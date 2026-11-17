/*
  Student Graduation Analytics - SQL Server
  File: 02_generate_synthetic_data.sql
  Purpose: Reproducible synthetic-data generator for the public portfolio repository.

  Target volumes:
    - 250 schools
    - 500,000 students
    - 500,000 graduation readiness records
    - 5,000,000 academic performance records
    - 10,000,000 attendance records

  IMPORTANT:
    This is a portfolio-safe reproducible generator aligned to the published model.
    It does not claim to be the exact historical script originally used to create the validated dataset.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* ---------- Helper tally source ---------- */
DROP TABLE IF EXISTS #N;
;WITH e1(n) AS (SELECT 1 FROM (VALUES(0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)),
e2(n) AS (SELECT 1 FROM e1 a CROSS JOIN e1 b),
e4(n) AS (SELECT 1 FROM e2 a CROSS JOIN e2 b),
e6(n) AS (SELECT 1 FROM e4 a CROSS JOIN e2 b)
SELECT TOP (1000000)
       ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
INTO #N
FROM e6;
CREATE UNIQUE CLUSTERED INDEX IX_N ON #N(n);
GO

/* ---------- 250 schools ---------- */
INSERT INTO dbo.DimSchool (SchoolKey, SchoolCode, SchoolName, SchoolType, Region, IsActive)
SELECT
    n,
    CONCAT('SCH', RIGHT('000' + CAST(n AS VARCHAR(3)), 3)),
    CASE WHEN n = 1 THEN 'Lakeview High School'
         ELSE CONCAT('Demo High School ', n) END,
    'High School',
    CASE (n - 1) % 5
        WHEN 0 THEN 'North'
        WHEN 1 THEN 'South'
        WHEN 2 THEN 'East'
        WHEN 3 THEN 'West'
        ELSE 'Central'
    END,
    1
FROM #N
WHERE n <= 250;
GO

/* ---------- 500,000 students; 2,000 per school ---------- */
INSERT INTO dbo.DimStudent
(
    StudentKey, StudentID, SchoolKey, GradeLevel, CohortYear,
    StudentGroup, EnrollmentDate, IsActive
)
SELECT
    n AS StudentKey,
    CONCAT('STU', RIGHT('0000000' + CAST(n AS VARCHAR(7)), 7)) AS StudentID,
    ((n - 1) % 250) + 1 AS SchoolKey,
    CAST(9 + ((n - 1) % 4) AS TINYINT) AS GradeLevel,
    CAST(2030 - ((n - 1) % 4) AS SMALLINT) AS CohortYear,
    CASE (ABS(CHECKSUM(CONCAT('group-', n))) % 4)
        WHEN 0 THEN 'General'
        WHEN 1 THEN 'ESE'
        WHEN 2 THEN 'ELL'
        ELSE 'Gifted'
    END AS StudentGroup,
    DATEADD(DAY, ABS(CHECKSUM(CONCAT('enroll-', n))) % 365, CAST('2025-08-01' AS DATE)) AS EnrollmentDate,
    1
FROM #N
WHERE n <= 500000;
GO

/* ---------- Date dimension ---------- */
DECLARE @StartDate DATE = '2025-08-01';
DECLARE @EndDate   DATE = '2026-12-31';

INSERT INTO dbo.DimDate (DateKey, FullDate, CalendarYear, CalendarMonth, MonthName, DayOfMonth, DayName)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), d.FullDate, 112)),
    d.FullDate,
    YEAR(d.FullDate),
    MONTH(d.FullDate),
    DATENAME(MONTH, d.FullDate),
    DAY(d.FullDate),
    DATENAME(WEEKDAY, d.FullDate)
FROM
(
    SELECT DATEADD(DAY, n - 1, @StartDate) AS FullDate
    FROM #N
    WHERE n <= DATEDIFF(DAY, @StartDate, @EndDate) + 1
) d;
GO

/* ---------- 500,000 graduation readiness records ----------
   The rules intentionally create realistic variation for portfolio analysis.
   Exact counts can vary from the previously validated snapshot because this
   script is a reproducible public generator, not the original random seed.
*/
INSERT INTO dbo.FactGraduationReadiness
(
    GraduationReadinessKey, StudentKey, SchoolKey, SnapshotDate,
    GradeLevel, GPA, CreditsEarned, AttendanceRate, ReadinessStatus
)
SELECT
    s.StudentKey,
    s.StudentKey,
    s.SchoolKey,
    CAST('2026-11-01' AS DATE),
    s.GradeLevel,
    x.GPA,
    x.CreditsEarned,
    x.AttendanceRate,
    CASE
        WHEN x.GPA >= 2.50 AND x.AttendanceRate >= 90.00 AND x.CreditsEarned >= 4.00 THEN 'On Track'
        WHEN x.GPA >= 1.75 AND x.AttendanceRate >= 85.00 THEN 'Moderate Risk'
        ELSE 'High Risk'
    END
FROM dbo.DimStudent s
CROSS APPLY
(
    SELECT
        CAST(1.00 + (ABS(CHECKSUM(CONCAT('gpa-', s.StudentKey))) % 301) / 100.0 AS DECIMAL(4,2)) AS GPA,
        CAST(2.00 + (ABS(CHECKSUM(CONCAT('credits-', s.StudentKey))) % 7) * 0.50 AS DECIMAL(5,2)) AS CreditsEarned,
        CAST(80.00 + (ABS(CHECKSUM(CONCAT('attendance-', s.StudentKey))) % 21) AS DECIMAL(5,2)) AS AttendanceRate
) x;
GO

/* ---------- 5,000,000 academic performance records ---------- */
INSERT INTO dbo.FactAcademicPerformance
(
    AcademicPerformanceKey, StudentKey, SchoolKey, PerformanceDate,
    SubjectName, CourseGrade
)
SELECT
    CAST(n AS BIGINT) AS AcademicPerformanceKey,
    ((n - 1) % 500000) + 1 AS StudentKey,
    (((n - 1) % 500000) % 250) + 1 AS SchoolKey,
    DATEADD(DAY, ABS(CHECKSUM(CONCAT('perf-date-', n))) % 300, CAST('2025-08-01' AS DATE)),
    CASE (n - 1) % 5
        WHEN 0 THEN 'English'
        WHEN 1 THEN 'Mathematics'
        WHEN 2 THEN 'Science'
        WHEN 3 THEN 'Social Studies'
        ELSE 'Elective'
    END,
    CAST(60 + ABS(CHECKSUM(CONCAT('grade-', n))) % 41 AS DECIMAL(5,2))
FROM
(
    SELECT TOP (5000000)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM #N a
    CROSS JOIN (VALUES(1),(2),(3),(4),(5)) b(x)
) q;
GO

/* ---------- 10,000,000 attendance records: 20 per student ---------- */
INSERT INTO dbo.FactAttendance
(
    AttendanceKey, StudentKey, SchoolKey, AttendanceDate,
    AttendanceStatus, IsPresent
)
SELECT
    CAST(((s.StudentKey - 1) * 20) + d.DayNumber AS BIGINT) AS AttendanceKey,
    s.StudentKey,
    s.SchoolKey,
    DATEADD(DAY, d.DayNumber - 1, CAST('2026-09-01' AS DATE)) AS AttendanceDate,
    CASE
        WHEN r.StatusBucket < 4 THEN 'Absent'
        WHEN r.StatusBucket < 8 THEN 'Tardy'
        ELSE 'Present'
    END AS AttendanceStatus,
    CASE WHEN r.StatusBucket < 4 THEN 0 ELSE 1 END AS IsPresent
FROM dbo.DimStudent s
CROSS JOIN
(
    SELECT n AS DayNumber
    FROM #N
    WHERE n <= 20
) d
CROSS APPLY
(
    SELECT ABS(CHECKSUM(CONCAT('att-', s.StudentKey, '-', d.DayNumber))) % 100 AS StatusBucket
) r;
GO

/* ---------- Volume checks ---------- */
SELECT 'DimSchool' AS TableName, COUNT_BIG(*) AS RowCount FROM dbo.DimSchool
UNION ALL SELECT 'DimStudent', COUNT_BIG(*) FROM dbo.DimStudent
UNION ALL SELECT 'FactGraduationReadiness', COUNT_BIG(*) FROM dbo.FactGraduationReadiness
UNION ALL SELECT 'FactAcademicPerformance', COUNT_BIG(*) FROM dbo.FactAcademicPerformance
UNION ALL SELECT 'FactAttendance', COUNT_BIG(*) FROM dbo.FactAttendance;
GO
