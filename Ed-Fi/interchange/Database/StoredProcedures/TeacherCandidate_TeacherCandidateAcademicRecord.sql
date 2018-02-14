IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_TeacherCandidateAcademicRecord_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateAcademicRecord_proc]
    END
 GO



CREATE PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateAcademicRecord_proc]
    (
      @iteration INT = 0 ,
      @maxRecords INT = 25000
    )
AS
    DECLARE @result XML;

    DECLARE @result_new XML; 

    DECLARE @startRow INT = ( @maxRecords * @iteration ) + 1

    DECLARE @endRow INT = ( @maxRecords * @iteration ) + @maxRecords

    IF ( EXISTS ( SELECT    *
                  FROM      INFORMATION_SCHEMA.TABLES
                  WHERE     TABLE_SCHEMA = 'staging'
                            AND TABLE_NAME = 'TEMPAcademicRecord' ) )
        BEGIN
            DROP TABLE staging.TEMPAcademicRecord
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPAcademicRecord
    FROM    ( SELECT    AcademicRecord.* ,
                        ROW_NUMBER() OVER ( ORDER BY [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ) RowNumber
              FROM      ( SELECT    * ,
                                    ROW_NUMBER() OVER ( PARTITION BY [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier],
                                                        [EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId] ORDER BY Priority ) AS Rowid
                          FROM      ( SELECT    TRY_CAST(a.Graduating_GPA AS DECIMAL(18,
                                                              4)) AS 'CumulativeGradePointAverage' ,
                                                CASE WHEN a.[Expected Program1 End Month] IS NULL
                                                     THEN NULL
                                                     ELSE 'Diploma Earned'
                                                END AS 'Diploma/Achievement/AchievementCategory/CodeValue' ,
                                                CASE WHEN a.[Expected Program1 End Month] IS NULL
                                                     THEN NULL
                                                     ELSE 'http://ed-fi.org/Descriptor/AchievementCategoryDescriptor.xml'
                                                END AS 'Diploma/Achievement/AchievementCategory/Namespace' ,
                                                CASE WHEN a.[Expected Program1 End Month] IS NULL
                                                     THEN NULL
                                                     ELSE a.[Expected Program1 End Year]
                                                          + '-' + RIGHT('0'
                                                              + CASE
                                                              WHEN a.[Expected Program1 End Month] = 'Spring'
                                                              THEN '6'
                                                              WHEN a.[Expected Program1 End Month] = 'Fall'
                                                              THEN '12'
                                                              WHEN a.[Expected Program1 End Month] = 'Summer'
                                                              THEN '8'
                                                              ELSE a.[Expected Program1 End Month]
                                                              END, 2) + '-01'
                                                END AS 'Diploma/DiplomaAwardDate' ,
                                                CASE WHEN a.[Expected Program1 End Month] IS NULL
                                                     THEN NULL
                                                     ELSE 'Other'
                                                END AS 'Diploma/DiplomaType' ,
                                                a.Institution_ID AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                                                ( CAST(( CASE WHEN a.[Expected Program1 End Month] >= 8
                                                              THEN 1
                                                              + a.[Expected Program1 End Year]
                                                              ELSE a.[Expected Program1 End Year]
                                                         END ) - 1 AS NVARCHAR(4))
                                                  + '-'
                                                  + CAST(CASE WHEN a.[Expected Program1 End Month] >= 8
                                                              THEN 1
                                                              + a.[Expected Program1 End Year]
                                                              ELSE a.[Expected Program1 End Year]
                                                         END AS NVARCHAR(4)) ) AS SchoolYear ,
                                                'Other' AS 'Term/CodeValue' ,
                                                'http://ed-fi.org/Descriptor/TermDescriptor.xml' AS 'Term/Namespace' ,
                                                a.SSN_Last_5
                                                + REPLACE(CONVERT(CHAR(10), CONVERT(DATETIME, a.Completer_Birth_Date), 111),
                                                          '/', '') AS 'TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier' ,
                                                TRY_CONVERT(DECIMAL(18, 4), a.Content_GPA) AS 'ContentGradePointAverage' ,
                                                'Gateway 1' AS 'ProgramGateway/CodeValue' ,
                                                'http://exchange.ed-fi.org/TPDP/Descriptor/ProgramGatewayDescriptor.xml' AS 'ProgramGateway/Namespace' ,
                                                'Other' AS 'TPPDegreeType/CodeValue' ,
                                                'http://exchange.ed-fi.org/TPDP/Descriptor/TPPDegreeTypeDescriptor.xml' AS 'TPPDegreeType/Namespace' ,
                                                TRY_CAST (a.Graduating_GPA AS DECIMAL(18,
                                                              4)) 'GraduatingGradePointAverage' ,
                                                TRY_CAST (B.[Candidate Admitting GPA] AS DECIMAL(18,
                                                              4)) AS AdmittingGPA ,
                                                1 'Priority'
                                      FROM      staging.Completers a
                                                LEFT JOIN staging.Admissions
                                                AS B ON a.SSN_Last_5 = B.[Candidate SSN]
                                                        AND a.Completer_Birth_Date = B.[Candidate Birth Date]
                                      WHERE     SSN_Last_5 IS NOT NULL
                                                AND Completer_Birth_Date IS NOT NULL
                                      UNION
                                      SELECT    TRY_CAST(B.Graduating_GPA AS DECIMAL(18,
                                                              4)) AS 'CumulativeGradePointAverage' ,
                                                NULL AS 'Diploma/Achievement/AchievementCategory/CodeValue' ,
                                                NULL AS 'Diploma/Achievement/AchievementCategory/Namespace' ,
                                                NULL AS 'Diploma/DiplomaAwardDate' ,
                                                NULL AS 'Diploma/DiplomaType' ,
                                                a.[Institution ID] AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                                                ( CAST(( CASE WHEN a.[Expected Program1 End Month] >= 8
                                                              THEN 1
                                                              + a.[Expected Program1 End Year]
                                                              ELSE a.[Expected Program1 End Year]
                                                         END ) - 1 AS NVARCHAR(4))
                                                  + '-'
                                                  + CAST(CASE WHEN a.[Expected Program1 End Month] >= 8
                                                              THEN 1
                                                              + a.[Expected Program1 End Year]
                                                              ELSE a.[Expected Program1 End Year]
                                                         END AS NVARCHAR(4)) ) AS SchoolYear ,
                                                'Other' AS 'Term/CodeValue' ,
                                                'http://ed-fi.org/Descriptor/TermDescriptor.xml' AS 'Term/Namespace' ,
                                                RIGHT(a.[Candidate SSN], 5)
                                                + REPLACE(CONVERT(CHAR(10), CONVERT(DATETIME, a.[Candidate Birth Date]), 111),
                                                          '/', '') AS 'TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier' ,
                                                TRY_CONVERT(DECIMAL(18, 4), B.Content_GPA) AS 'ContentGradePointAverage' ,
                                                'Gateway 1' AS 'ProgramGateway/CodeValue' ,
                                                'http://exchange.ed-fi.org/TPDP/Descriptor/ProgramGatewayDescriptor.xml' AS 'ProgramGateway/Namespace' ,
                                                'Other' AS 'TPPDegreeType/CodeValue' ,
                                                'http://exchange.ed-fi.org/TPDP/Descriptor/TPPDegreeTypeDescriptor.xml' AS 'TPPDegreeType/Namespace' ,
                                                TRY_CAST(B.Graduating_GPA AS DECIMAL(18,
                                                              4)) AS GraduatingGradePointAverage ,
                                                TRY_CAST(a.[Candidate Admitting GPA] AS DECIMAL(18,
                                                              4)) 'AdmittingGPA' ,
                                                2 'Priorty'
                                      FROM      staging.Admissions a
                                                LEFT JOIN staging.Completers
                                                AS B ON a.[Candidate SSN] = B.SSN_Last_5
                                                        AND a.[Candidate Birth Date] = B.Completer_Birth_Date
                                      WHERE     [Candidate Birth Date] IS NOT NULL
                                                AND [Candidate SSN] IS NOT NULL
                                    ) a
                        ) AcademicRecord
              WHERE     AcademicRecord.Rowid = 1
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    
    SELECT  [CumulativeGradePointAverage] ,
            [Diploma/Achievement/AchievementCategory/CodeValue] ,
            [Diploma/Achievement/AchievementCategory/Namespace] ,
            [Diploma/DiplomaAwardDate] ,
            [Diploma/DiplomaType] ,
            [EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId] ,
            [SchoolYear] ,
            [Term/CodeValue] ,
            [Term/Namespace] ,
            [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ,
            [ContentGradePointAverage] ,
            [ProgramGateway/CodeValue] ,
            [ProgramGateway/Namespace] ,
            [TPPDegreeType/CodeValue] ,
            [TPPDegreeType/Namespace] ,
            [GraduatingGradePointAverage] ,
            [AdmittingGPA]
    FROM    [staging].[TEMPAcademicRecord]
    FOR     XML PATH('TeacherCandidateAcademicRecord') ,
                ROOT('InterchangeTeacherCandidate')
                              
    DROP TABLE staging.TEMPAcademicRecord












GO


