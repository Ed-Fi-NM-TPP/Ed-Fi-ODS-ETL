IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_Student_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_Student_proc]
    END
 GO




CREATE PROCEDURE [mapping].[TeacherCandidate_Student_proc]
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
                            AND TABLE_NAME = 'TEMPStudent' ) )
        BEGIN
            DROP TABLE staging.TEMPStudent
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPStudent
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY StudentUniqueId ) AS RowNumber
              FROM      ( SELECT DISTINCT
                                    TeacherCandidateIdentifier AS StudentUniqueId ,
                                    Students.FirstName AS 'Name/FirstName' ,
                                    Students.LastSurname AS 'Name/LastSurname' ,
                                    CASE WHEN Gender = 'M' THEN 'Male'
                                         WHEN Gender = 'F' THEN 'Female'
                                         ELSE 'Not Selected'
                                    END AS Sex ,
                                    CONVERT(CHAR(10), BirthDate, 111) AS 'BirthData/BirthDate' ,
                                    CASE WHEN NMEthnicity LIKE 'Hispanic'
                                         THEN 'true'
                                         ELSE 'false'
                                    END 'HispanicLatinoEthnicity'
                          FROM      staging.TeacherCandidates Students
                        ) Students
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    
    SELECT  [StudentUniqueId] ,
            [Name/FirstName] ,
            [Name/LastSurname] ,
            [Sex] ,
            [BirthData/BirthDate] ,
            [HispanicLatinoEthnicity]
    FROM    [staging].[TEMPStudent]
    FOR     XML PATH('Student') ,
                ROOT('InterchangeTeacherCandidate')
                              
    DROP TABLE staging.TEMPStudent





GO


