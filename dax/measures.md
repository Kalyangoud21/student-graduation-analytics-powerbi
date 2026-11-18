
# Power BI DAX Measures

This document contains the key DAX measures used in the **Student Graduation Analytics** Power BI portfolio project.

The measures support district-level KPIs, graduation readiness analysis, academic performance reporting, drill-through analysis, and dynamic student filtering.

> **Note:** This project uses fully synthetic education data. No real student or school records are included.

---

## 1. Total Students

Calculates the distinct number of students represented in the graduation readiness dataset.

```DAX
Total Students =
DISTINCTCOUNT ( FactGraduationReadiness[StudentKey] )
```

**Validated result:** `500,000`

---

## 2. On Track Students

Calculates the number of students whose graduation readiness status is **On Track**.

```DAX
On Track Students =
CALCULATE (
    DISTINCTCOUNT ( FactGraduationReadiness[StudentKey] ),
    FactGraduationReadiness[ReadinessStatus] = "On Track"
)
```

**Validated result:** `58,229`

---

## 3. Moderate Risk Students

Calculates the number of students classified as **Moderate Risk**.

```DAX
Moderate Risk Students =
CALCULATE (
    DISTINCTCOUNT ( FactGraduationReadiness[StudentKey] ),
    FactGraduationReadiness[ReadinessStatus] = "Moderate Risk"
)
```

**Validated result:** `215,162`

---

## 4. High Risk Students

Calculates the number of students classified as **High Risk**.

```DAX
High Risk Students =
CALCULATE (
    DISTINCTCOUNT ( FactGraduationReadiness[StudentKey] ),
    FactGraduationReadiness[ReadinessStatus] = "High Risk"
)
```

**Validated result:** `226,609`

---

## 5. On Track %

Calculates the percentage of students currently classified as On Track.

```DAX
On Track % =
DIVIDE (
    [On Track Students],
    [Total Students],
    0
)
```

**Validated result:** `11.65%`

---

## 6. Moderate Risk %

Calculates the percentage of students classified as Moderate Risk.

```DAX
Moderate Risk % =
DIVIDE (
    [Moderate Risk Students],
    [Total Students],
    0
)
```

**Validated result:** `43.03%`

---

## 7. High Risk %

Calculates the percentage of students classified as High Risk.

```DAX
High Risk % =
DIVIDE (
    [High Risk Students],
    [Total Students],
    0
)
```

**Validated result:** `45.32%`

---

## 8. Average GPA

Calculates the average GPA for the students within the current report filter context.

```DAX
Average GPA =
AVERAGE ( FactGraduationReadiness[GPA] )
```

**District-wide validated result:** `2.0392`

The Power BI report displays the result rounded to two decimal places.

---

## 9. Average Attendance %

Calculates average student attendance within the current report filter context.

`AttendanceRate` is stored on a 0–100 scale in the synthetic dataset.

```DAX
Average Attendance % =
AVERAGE ( FactGraduationReadiness[AttendanceRate] ) / 100
```

The measure is formatted as a percentage in Power BI.

**District-wide validated result:** `95.70%`

---

## 10. Student Search Available

This measure supports dynamic filtering of the **Student Search** slicer.

It ensures that the slicer only displays students who have graduation-readiness records matching the currently selected report filters, such as school, grade level, and readiness status.

```DAX
Student Search Available =
IF (
    COUNTROWS ( FactGraduationReadiness ) > 0,
    1,
    0
)
```

The Student Search slicer applies a visual-level filter:

```text
Student Search Available = 1
```

This allows selections such as **High Risk** to limit the Student Search list to students relevant to the current filter context.

---

# Measure Usage

The measures are used throughout two Power BI report pages.

## Academic Readiness Overview

Measures support:

- Total student population
- On Track student count
- Moderate Risk student count
- High Risk student count
- On Track %
- Moderate Risk %
- High Risk %
- Graduation readiness distribution
- Top 10 Schools by On Track %
- Graduation readiness by grade level
- Graduation readiness by region
- Average GPA by grade level
- Average Attendance % by grade level

## Student Detail Report

Measures support:

- Academic Risk Summary
- Average GPA
- Average Attendance %
- High Risk student count
- Dynamic Student Search filtering
- Drill-through analysis
- Student-level investigation

---

# Filter Context

The measures are intentionally designed to respond to Power BI filter context.

Depending on the report page, results can dynamically change based on:

- School
- Region
- Grade Level
- Readiness Status
- Student
- Drill-through context

For example, drilling through from a school on the Academic Readiness Overview passes the selected school context to the Student Detail Report. The measures then recalculate for that school automatically.

---

# Validation

The primary DAX results were reconciled against SQL Server before the dashboard was finalized.

| Metric | Validated Result |
|---|---:|
| Total Students | 500,000 |
| On Track Students | 58,229 |
| Moderate Risk Students | 215,162 |
| High Risk Students | 226,609 |
| On Track % | 11.65% |
| Moderate Risk % | 43.03% |
| High Risk % | 45.32% |
| Average GPA | 2.0392 |
| Average Attendance | 95.70% |

Additional SQL validation was performed for:

- Top 10 schools by On Track %
- Graduation readiness by grade level
- Graduation readiness by region
- Individual student records
- GPA
- Credits earned
- Attendance
- Graduation readiness classification

---

## Dynamic Row-Level Security (RLS)

The Power BI semantic model implements dynamic Region-based Row-Level Security using a `UserSecurity` mapping table.

### Security Role

**Role Name:** `RegionalManager`

**Table:** `UserSecurity`

**RLS Filter Expression:**

```DAX
UserSecurity[UserEmail] = USERPRINCIPALNAME()
```

### Security Filter Propagation

The security filter propagates through the following relationships:

`UserSecurity → DimSchool → FactGraduationReadiness`

This restricts graduation-readiness metrics, school-level analysis, and student-level records to the user's authorized region.

### RLS Validation Results

| Test User | Authorized Region | Result |
|---|---|---|
| north.manager@demo.com | North | Passed |
| south.manager@demo.com | South | Passed |
| unauthorized.user@demo.com | None | No data returned |

Additional validation confirmed that school-level drill-through respects the regional security restrictions.

**Note:** All user accounts are synthetic and used only for portfolio demonstration. The RLS expression is a model security-role filter, not a regular DAX measure.

## Portfolio Disclaimer

**Synthetic data only — no real student or school records are used.**

These measures were developed as part of an end-to-end SQL Server and Power BI analytics portfolio project.
