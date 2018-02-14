IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_TeacherCandidateFieldworkExperience_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateFieldworkExperience_proc]
    END
 GO



CREATE PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateFieldworkExperience_proc]
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
                            AND TABLE_NAME = 'TEMPTeacherCandidateFieldworkExperience' ) )
        BEGIN
            DROP TABLE staging.TEMPTeacherCandidateFieldworkExperience
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPTeacherCandidateFieldworkExperience
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY a.Institution_ID ) AS RowNumber
              FROM      ( SELECT DISTINCT
                                    a.staffuniqueid ,
                                    a.Alternative_Internship_Year_School ,
                                    a.Hours_Student_Teaching_School ,
                                    a.Student_Teaching_District ,
                                    a.CT_First_Name ,
                                    a.CT_MI ,
                                    a.CT_Last_Name ,
                                    a.completer_birth_date ,
                                    a.ssn_last_5 ,
                                    a.Institution_ID ,
                                    a.Institution_Name ,
                                    vcissscse.LOCATION_ID
                          FROM      staging.CompletersPivoted a
                                    INNER JOIN staging.STAFF AS s ON RIGHT(s.STAFF_ID,
                                                              5) = a.ssn_last_5
                                                              AND STAFF_BIRTHDATE = Completer_birth_date
                                    INNER JOIN staging.vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll
                                    AS vcissscse ON vcissscse.STAFF_ID = s.STAFF_ID
                          WHERE     vcissscse.SCHOOL_YEAR = 2017
                        ) a
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    SELECT  staffuniqueid + CAST(RowNumber AS NVARCHAR(10)) AS 'FieldworkIdentifier' ,
            staffuniqueid AS 'TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier' ,
            LOCATION_ID AS 'FieldworkExperienceSchoolReference/SchoolIdentity/SchoolId' ,
            'Field Placement' AS 'FieldworkType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/FieldworkTypeDescriptor.xml' AS 'FieldworkType/Namespace' ,
            ( SELECT TOP 1
                        CAST(C.[Expected Program1 End Year] AS NVARCHAR(4))
                        + '-' + RIGHT('0'
                                      + CAST(C.[Expected Program1 End Month] AS NVARCHAR(2)),
                                      2) + '-01'
              FROM      staging.Completers C
              WHERE     LTRIM(RTRIM(a.ssn_last_5)) = LTRIM(RTRIM(C.SSN_Last_5))
                        AND TRY_CONVERT(DATETIME, C.Completer_Birth_Date, 111) = TRY_CONVERT(DATETIME, a.completer_birth_date, 111)
              ORDER BY  C.[Expected Program1 End Year]
            ) AS 'BeginDate' ,
            ( SELECT    CASE WHEN Alternative_Internship_Year_School LIKE 'Y%'
                             THEN 'true'
                             WHEN Alternative_Internship_Year_School LIKE 'N%'
                             THEN 'false'
                             ELSE NULL
                        END 'Internship' ,
                        Hours_Student_Teaching_School AS 'HoursPerWeek' ,
                        Student_Teaching_District AS 'FieldworkSchool' ,
                        ( SELECT    CT_First_Name AS 'FirstName' ,
                                    CT_MI AS 'MiddleName' ,
                                    CT_Last_Name AS 'LastSurname'
                          FROM      staging.TEMPTeacherCandidateFieldworkExperience C
                          WHERE     C.RowNumber = b.RowNumber
                                    AND C.staffuniqueid = b.staffuniqueid
                                    AND CT_First_Name IS NOT NULL
                                    AND CT_First_Name NOT LIKE ''
                                    AND CT_Last_Name IS NOT NULL
                                    AND CT_Last_Name NOT LIKE ''
                        FOR
                          XML PATH('CoordinatingTeacherName') ,
                              TYPE
                        )
              FROM      staging.TEMPTeacherCandidateFieldworkExperience B
              WHERE     ( Hours_Student_Teaching_School IS NOT NULL
                          AND Hours_Student_Teaching_School NOT LIKE ''
                        )
                        AND ( Student_Teaching_District IS NOT NULL
                              AND Student_Teaching_District NOT LIKE ''
                            )
                        AND A.RowNumber = B.RowNumber
                        AND A.staffuniqueid = B.staffuniqueid
            FOR
              XML PATH('FieldworkInformation') ,
                  TYPE
            )
    FROM    staging.TEMPTeacherCandidateFieldworkExperience A
    FOR     XML PATH('TeacherCandidateFieldworkExperience') ,
                ROOT('InterchangeTeacherCandidate')
                                    
    DROP TABLE staging.TEMPTeacherCandidateFieldworkExperience









GO


