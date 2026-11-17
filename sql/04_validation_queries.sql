/*
  Student Graduation Analytics - SQL Server
  File: 04_validation_queries.sql
  Purpose: Reconcile SQL Server results with Power BI visuals and measures.
*/

SET NOCOUNT ON;
GO

/* 1. Overall student/readiness distribution */
SELECT
    COUNT(DISTINCT StudentKey) AS TotalStudents,
    COUNT(DISTINCT CASE WHEN ReadinessStatus = 'On Track' THEN StudentKey END) AS OnTrackStudents,
    COUNT(DISTINCT CASE WHEN ReadinessStatus = 'Moderate Risk' THEN StudentKey END) AS ModerateRiskStudents,
    COUNT(DISTINCT CASE WHEN ReadinessStatus = 'High Risk' THEN StudentKey END) AS HighRiskStudents
FROM dbo.FactGraduationReadiness;
GO

/* Validated portfolio snapshot:
   TotalStudents        = 500000
   OnTrackStudents      = 58229
   ModerateRiskStudents = 215162
   HighRiskStudents     = 226609
*/

/* 2. District-wide average GPA and attendance */
SELECT
    CAST(AVG(CAST(GPA AS FLOAT)) AS DECIMAL(10,4)) AS AverageGPA,
    CAST(AVG(CAST(AttendanceRate AS FLOAT)) AS DECIMAL(10,4)) AS AverageAttendance
FROM dbo.FactGraduationReadiness;
GO

/* Validated portfolio snapshot:
   AverageGPA        = 2.0392
   AverageAttendance = 95.7000
*/

/* 3. Top 10 schools by On Track percentage */
SELECT TOP (10)
    s.SchoolName,
    COUNT(*) AS TotalStudents,
    SUM(CASE WHEN f.ReadinessStatus = 'On Track' THEN 1 ELSE 0 END) AS OnTrackStudents,
    CAST(
        100.0 * SUM(CASE WHEN f.ReadinessStatus = 'On Track' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS OnTrackPercentage
FROM dbo.FactGraduationReadiness f
INNER JOIN dbo.DimSchool s
    ON f.SchoolKey = s.SchoolKey
GROUP BY s.SchoolKey, s.SchoolName
ORDER BY OnTrackPercentage DESC, s.SchoolName ASC;
GO

/* 4. Graduation readiness by grade level */
SELECT
    GradeLevel,
    COUNT(*) AS TotalStudents,
    SUM(CASE WHEN ReadinessStatus = 'On Track' THEN 1 ELSE 0 END) AS OnTrack,
    SUM(CASE WHEN ReadinessStatus = 'Moderate Risk' THEN 1 ELSE 0 END) AS ModerateRisk,
    SUM(CASE WHEN ReadinessStatus = 'High Risk' THEN 1 ELSE 0 END) AS HighRisk
FROM dbo.FactGraduationReadiness
GROUP BY GradeLevel
ORDER BY GradeLevel;
GO

/* Validated portfolio snapshot:
Grade  Total     OnTrack  ModerateRisk  HighRisk
9      125000    15675    54583         54742
10     125000    15036    55224         54740
11     125000    15356    54782         54862
12     125000    12162    50573         62265
*/

/* 5. Graduation readiness by region */
SELECT
    s.Region,
    COUNT(*) AS TotalStudents,
    SUM(CASE WHEN f.ReadinessStatus = 'On Track' THEN 1 ELSE 0 END) AS OnTrack,
    SUM(CASE WHEN f.ReadinessStatus = 'Moderate Risk' THEN 1 ELSE 0 END) AS ModerateRisk,
    SUM(CASE WHEN f.ReadinessStatus = 'High Risk' THEN 1 ELSE 0 END) AS HighRisk
FROM dbo.FactGraduationReadiness f
INNER JOIN dbo.DimSchool s
    ON f.SchoolKey = s.SchoolKey
GROUP BY s.Region
ORDER BY s.Region;
GO

/* Validated portfolio snapshot:
Central 100000 11735 43023 45242
East    100000 11841 42856 45303
North   100000 11361 43298 45341
South   100000 11460 43162 45378
West    100000 11832 42823 45345
*/

/* 6. Student-level validation */
SELECT TOP (1)
    s.StudentID,
    sc.SchoolName,
    f.GradeLevel,
    f.GPA,
    f.CreditsEarned,
    f.AttendanceRate,
    f.ReadinessStatus
FROM dbo.FactGraduationReadiness f
INNER JOIN dbo.DimStudent s
    ON f.StudentKey = s.StudentKey
INNER JOIN dbo.DimSchool sc
    ON f.SchoolKey = sc.SchoolKey
ORDER BY s.StudentID;
GO

/* Validated portfolio record:
   StudentID       = STU0000001
   SchoolName      = Lakeview High School
   GradeLevel      = 9
   GPA             = 2.30
   CreditsEarned   = 4.00
   AttendanceRate  = 95.00
   ReadinessStatus = Moderate Risk
*/

/* 7. Attendance status distribution */
SELECT
    AttendanceStatus,
    COUNT_BIG(*) AS RecordCount
FROM dbo.FactAttendance
GROUP BY AttendanceStatus
ORDER BY AttendanceStatus;
GO

/* Validated portfolio snapshot:
   Present = 9,180,002
   Absent  =   429,997
   Tardy   =   390,001
   Total   = 10,000,000
*/

/* 8. Confirm no duplicate student/date attendance records */
SELECT
    StudentKey,
    AttendanceDate,
    COUNT(*) AS DuplicateCount
FROM dbo.FactAttendance
GROUP BY StudentKey, AttendanceDate
HAVING COUNT(*) > 1;
GO

/* Expected: no rows */

/* 9. Row-count checks */
SELECT 'DimSchool' AS ObjectName, COUNT_BIG(*) AS RowCount FROM dbo.DimSchool
UNION ALL SELECT 'DimStudent', COUNT_BIG(*) FROM dbo.DimStudent
UNION ALL SELECT 'FactGraduationReadiness', COUNT_BIG(*) FROM dbo.FactGraduationReadiness
UNION ALL SELECT 'FactAcademicPerformance', COUNT_BIG(*) FROM dbo.FactAcademicPerformance
UNION ALL SELECT 'FactAttendance', COUNT_BIG(*) FROM dbo.FactAttendance;
GO
