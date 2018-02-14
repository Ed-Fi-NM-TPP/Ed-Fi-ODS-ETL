
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_TeacherCandidateTeacherPreparationProviderAssociation_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateTeacherPreparationProviderAssociation_proc]
    END
 GO




CREATE PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateTeacherPreparationProviderAssociation_proc]
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
                            AND TABLE_NAME = 'TEMPTeacherCandidateAssociation' ) )
        BEGIN
            DROP TABLE staging.TEMPTeacherCandidateAssociation
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPTeacherCandidateAssociation
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ) RowNumber
              FROM      ( SELECT DISTINCT
                                    TeacherCandidate.TeacherCandidateIdentifier AS 'TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier' ,
                                    REPLACE(TeacherCandidate.EducationOrganizationId,
                                            ' ', '') AS 'TeacherPreparationProviderReference/TeacherPreparationProviderIdentity/TeacherPreparationProviderId' ,
                                    TeacherCandidate.EntryDate AS 'EntryDate' ,
                                    TeacherCandidate.EndDate AS 'ExitWithdrawDate' ,
                                    TeacherCandidate.AdmissionStatus AS 'AdmissionStatus' ,
                                    TeacherCandidate.EndMonth AS 'ExpectedEndMonth' ,
                                    TeacherCandidate.EndYear AS 'ExpectedEndYear' ,
                                    CASE WHEN TeacherCandidate.FileStatus LIKE 'Admissions'
                                         THEN TeacherCandidate.StartMonth
                                    END AS 'AdmissionStartMonth' ,
                                    CASE WHEN TeacherCandidate.FileStatus LIKE 'Admissions'
                                         THEN TeacherCandidate.StartYear
                                    END AS 'AdmissionStartYear' ,
                                    CASE WHEN TeacherCandidate.FileStatus LIKE 'Completers'
                                         THEN TeacherCandidate.StartMonth
                                    END AS 'CompleterStartMonth' ,
                                    CASE WHEN TeacherCandidate.FileStatus LIKE 'Completers'
                                         THEN TeacherCandidate.StartYear
                                    END AS 'CompleterStartYear' ,
                                    TeacherCandidate.FileStatus AS 'FileStatus' ,
                                    DENSE_RANK() OVER ( PARTITION BY TeacherCandidate.TeacherCandidateIdentifier,
                                                        TeacherCandidate.EducationOrganizationId ORDER BY TeacherCandidate.FileStatus DESC ) AS RowId
                          FROM      [staging].[TeacherCandidateTeacherPreparationProviderAssociation]
                                    AS TeacherCandidate
                        ) TeacherCandidateAssociation
              WHERE     TeacherCandidateAssociation.RowId = 1
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    
    SELECT  [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ,
            [TeacherPreparationProviderReference/TeacherPreparationProviderIdentity/TeacherPreparationProviderId] ,
            [EntryDate] ,
            [ExitWithdrawDate] ,
            [AdmissionStatus] ,
            [ExpectedEndMonth] ,
            [ExpectedEndYear] ,
            [AdmissionStartMonth] ,
            [AdmissionStartYear] ,
            [CompleterStartMonth] ,
            [CompleterStartYear] ,
            [FileStatus]
    FROM    [staging].[TEMPTeacherCandidateAssociation]
    FOR     XML PATH('TeacherCandidateTeacherPreparationProviderAssociation') ,
                ROOT('InterchangeTeacherCandidate')
                              
    DROP TABLE staging.TEMPTeacherCandidateAssociation








GO


