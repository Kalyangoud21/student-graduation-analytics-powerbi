/*
  Student Graduation Analytics - SQL Server
  File: 01_create_tables.sql
  Purpose: Create the core dimensional and fact tables used by the Power BI portfolio project.
  Note: All data used by this project is synthetic.
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Drop fact tables first when rebuilding a development database.
DROP TABLE IF EXISTS dbo.FactAttendance;
DROP TABLE IF EXISTS dbo.FactAcademicPerformance;
DROP TABLE IF EXISTS dbo.FactGraduationReadiness;
DROP TABLE IF EXISTS dbo.DimStudent;
DROP TABLE IF EXISTS dbo.DimSchool;
DROP TABLE IF EXISTS dbo.DimDate;
GO

CREATE TABLE dbo.DimSchool
(
    SchoolKey      INT           NOT NULL PRIMARY KEY,
    SchoolCode     VARCHAR(20)   NOT NULL,
    SchoolName     VARCHAR(150)  NOT NULL,
    SchoolType     VARCHAR(50)   NOT NULL,
    Region         VARCHAR(30)   NOT NULL,
    IsActive       BIT           NOT NULL CONSTRAINT DF_DimSchool_IsActive DEFAULT (1),
    LoadDate       DATETIME2(0)  NOT NULL CONSTRAINT DF_DimSchool_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_DimSchool_SchoolCode UNIQUE (SchoolCode)
);
GO

CREATE TABLE dbo.DimStudent
(
    StudentKey     INT           NOT NULL PRIMARY KEY,
    StudentID      VARCHAR(20)   NOT NULL,
    SchoolKey      INT           NOT NULL,
    GradeLevel     TINYINT       NOT NULL,
    CohortYear     SMALLINT      NULL,
    StudentGroup   VARCHAR(50)   NOT NULL,
    EnrollmentDate DATE          NOT NULL,
    IsActive       BIT           NOT NULL CONSTRAINT DF_DimStudent_IsActive DEFAULT (1),
    LoadDate       DATETIME2(0)  NOT NULL CONSTRAINT DF_DimStudent_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_DimStudent_StudentID UNIQUE (StudentID),
    CONSTRAINT FK_DimStudent_DimSchool FOREIGN KEY (SchoolKey) REFERENCES dbo.DimSchool(SchoolKey),
    CONSTRAINT CK_DimStudent_GradeLevel CHECK (GradeLevel BETWEEN 9 AND 12)
);
GO

CREATE TABLE dbo.DimDate
(
    DateKey        INT           NOT NULL PRIMARY KEY,
    FullDate       DATE          NOT NULL,
    CalendarYear   SMALLINT      NOT NULL,
    CalendarMonth  TINYINT       NOT NULL,
    MonthName      VARCHAR(20)   NOT NULL,
    DayOfMonth     TINYINT       NOT NULL,
    DayName        VARCHAR(20)   NOT NULL,
    CONSTRAINT UQ_DimDate_FullDate UNIQUE (FullDate)
);
GO

CREATE TABLE dbo.FactGraduationReadiness
(
    GraduationReadinessKey BIGINT        NOT NULL PRIMARY KEY,
    StudentKey             INT           NOT NULL,
    SchoolKey              INT           NOT NULL,
    SnapshotDate           DATE          NOT NULL,
    GradeLevel             TINYINT       NOT NULL,
    GPA                    DECIMAL(4,2)  NOT NULL,
    CreditsEarned          DECIMAL(5,2)  NOT NULL,
    AttendanceRate         DECIMAL(5,2)  NOT NULL,
    ReadinessStatus        VARCHAR(30)   NOT NULL,
    LoadDate               DATETIME2(0)  NOT NULL CONSTRAINT DF_FGR_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_FGR_Student FOREIGN KEY (StudentKey) REFERENCES dbo.DimStudent(StudentKey),
    CONSTRAINT FK_FGR_School  FOREIGN KEY (SchoolKey) REFERENCES dbo.DimSchool(SchoolKey),
    CONSTRAINT CK_FGR_Grade CHECK (GradeLevel BETWEEN 9 AND 12),
    CONSTRAINT CK_FGR_Attendance CHECK (AttendanceRate BETWEEN 0 AND 100),
    CONSTRAINT CK_FGR_Status CHECK (ReadinessStatus IN ('On Track','Moderate Risk','High Risk'))
);
GO

CREATE TABLE dbo.FactAcademicPerformance
(
    AcademicPerformanceKey BIGINT        NOT NULL PRIMARY KEY,
    StudentKey             INT           NOT NULL,
    SchoolKey              INT           NOT NULL,
    PerformanceDate        DATE          NOT NULL,
    SubjectName            VARCHAR(50)   NOT NULL,
    CourseGrade            DECIMAL(5,2)  NULL,
    LoadDate               DATETIME2(0)  NOT NULL CONSTRAINT DF_FAP_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_FAP_Student FOREIGN KEY (StudentKey) REFERENCES dbo.DimStudent(StudentKey),
    CONSTRAINT FK_FAP_School  FOREIGN KEY (SchoolKey) REFERENCES dbo.DimSchool(SchoolKey)
);
GO

CREATE TABLE dbo.FactAttendance
(
    AttendanceKey     BIGINT        NOT NULL PRIMARY KEY,
    StudentKey        INT           NOT NULL,
    SchoolKey         INT           NOT NULL,
    AttendanceDate    DATE          NOT NULL,
    AttendanceStatus  VARCHAR(20)   NOT NULL,
    IsPresent         BIT           NOT NULL,
    LoadDate          DATETIME2(0)  NOT NULL CONSTRAINT DF_FA_LoadDate DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_FA_Student FOREIGN KEY (StudentKey) REFERENCES dbo.DimStudent(StudentKey),
    CONSTRAINT FK_FA_School  FOREIGN KEY (SchoolKey) REFERENCES dbo.DimSchool(SchoolKey),
    CONSTRAINT CK_FA_Status CHECK (AttendanceStatus IN ('Present','Absent','Tardy'))
);
GO

CREATE INDEX IX_FGR_StudentKey ON dbo.FactGraduationReadiness(StudentKey);
CREATE INDEX IX_FGR_SchoolKey_Status ON dbo.FactGraduationReadiness(SchoolKey, ReadinessStatus);
CREATE INDEX IX_FGR_GradeLevel ON dbo.FactGraduationReadiness(GradeLevel);
CREATE INDEX IX_FA_StudentKey_Date ON dbo.FactAttendance(StudentKey, AttendanceDate);
CREATE INDEX IX_FAP_StudentKey ON dbo.FactAcademicPerformance(StudentKey);
GO
