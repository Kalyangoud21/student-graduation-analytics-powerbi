/*
  Student Graduation Analytics - SQL Server
  File: 03_create_views.sql
  Purpose: Create reusable reporting/summary views for Power BI.
*/

SET NOCOUNT ON;
GO

CREATE OR ALTER VIEW dbo.vw_StudentAttendanceSummary
AS
SELECT
    StudentKey,
    COUNT_BIG(*) AS TotalAttendanceDays,
    SUM(CASE WHEN AttendanceStatus = 'Absent'  THEN 1 ELSE 0 END) AS DaysAbsent,
    SUM(CASE WHEN AttendanceStatus = 'Tardy'   THEN 1 ELSE 0 END) AS DaysTardy,
    SUM(CASE WHEN AttendanceStatus = 'Present' THEN 1 ELSE 0 END) AS DaysPresent
FROM dbo.FactAttendance
GROUP BY StudentKey;
GO

CREATE OR ALTER VIEW dbo.vw_StudentGraduationReadiness
AS
SELECT
    s.StudentKey,
    s.StudentID,
    sc.SchoolKey,
    sc.SchoolCode,
    sc.SchoolName,
    sc.SchoolType,
    sc.Region,
    f.SnapshotDate,
    f.GradeLevel,
    s.CohortYear,
    s.StudentGroup,
    s.EnrollmentDate,
    s.IsActive,
    f.GPA,
    f.CreditsEarned,
    f.AttendanceRate,
    f.ReadinessStatus
FROM dbo.FactGraduationReadiness f
INNER JOIN dbo.DimStudent s
    ON f.StudentKey = s.StudentKey
INNER JOIN dbo.DimSchool sc
    ON f.SchoolKey = sc.SchoolKey;
GO

CREATE OR ALTER VIEW dbo.vw_SchoolReadinessSummary
AS
SELECT
    sc.SchoolKey,
    sc.SchoolCode,
    sc.SchoolName,
    sc.SchoolType,
    sc.Region,
    COUNT_BIG(*) AS TotalStudents,
    SUM(CASE WHEN f.ReadinessStatus = 'On Track' THEN 1 ELSE 0 END) AS OnTrackStudents,
    SUM(CASE WHEN f.ReadinessStatus = 'Moderate Risk' THEN 1 ELSE 0 END) AS ModerateRiskStudents,
    SUM(CASE WHEN f.ReadinessStatus = 'High Risk' THEN 1 ELSE 0 END) AS HighRiskStudents,
    CAST(100.0 * SUM(CASE WHEN f.ReadinessStatus = 'On Track' THEN 1 ELSE 0 END)
         / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,2)) AS OnTrackPct,
    CAST(100.0 * SUM(CASE WHEN f.ReadinessStatus = 'Moderate Risk' THEN 1 ELSE 0 END)
         / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,2)) AS ModerateRiskPct,
    CAST(100.0 * SUM(CASE WHEN f.ReadinessStatus = 'High Risk' THEN 1 ELSE 0 END)
         / NULLIF(COUNT_BIG(*), 0) AS DECIMAL(10,2)) AS HighRiskPct
FROM dbo.FactGraduationReadiness f
INNER JOIN dbo.DimSchool sc
    ON f.SchoolKey = sc.SchoolKey
GROUP BY
    sc.SchoolKey, sc.SchoolCode, sc.SchoolName, sc.SchoolType, sc.Region;
GO
