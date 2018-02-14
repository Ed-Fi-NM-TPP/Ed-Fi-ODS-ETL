
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_TeacherCandidateTeacherPreparationProviderProgramAssociation_proc' )
    BEGIN
        DROP  PROCEDURE mapping.TeacherCandidate_TeacherCandidateTeacherPreparationProviderProgramAssociation_proc
    END
 GO


CREATE PROCEDURE [mapping].[TeacherCandidate_TeacherCandidateTeacherPreparationProviderProgramAssociation_proc]
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
                            AND TABLE_NAME = 'TEMPTeacherCandidateProgramAssociation' ) )
        BEGIN
            DROP TABLE staging.TEMPTeacherCandidateProgramAssociation
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPTeacherCandidateProgramAssociation
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ) RowNumber
              FROM      ( SELECT DISTINCT
                                    a.TeacherCandidateIdentifier AS 'TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier' ,
                                    a.EntryDate AS 'BeginDate' ,
                                    a.EducationOrganizationId AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId'
                          FROM      [staging].[TeacherCandidateTeacherPreparationProviderAssociation]
                                    AS a
                          WHERE     a.TeacherCandidateIdentifier IS NOT NULL
                        ) TeacherCandidateProgramAssociation
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    
    SELECT  [TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] ,
            ( SELECT  DISTINCT
                        B.EducationOrganizationId AS 'TeacherPreparationProviderProgramIdentity/EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        'Traditional undergraduate' AS 'TeacherPreparationProviderProgramIdentity/ProgramName' ,
                        'Other' AS 'TeacherPreparationProviderProgramIdentity/ProgramType'
              FROM      staging.TeacherCandidateTeacherPreparationProviderAssociation B
              WHERE     A.[TeacherCandidateReference/TeacherCandidateIdentity/TeacherCandidateIdentifier] = B.TeacherCandidateIdentifier
                        AND B.EducationOrganizationId = B.EducationOrganizationId
                        AND B.EducationOrganizationId IS NOT NULL
                        AND B.TeacherCandidateIdentifier IS NOT NULL
            FOR
              XML PATH('TeacherPreparationProviderProgramReference') ,
                  TYPE
            ) ,
            [BeginDate] ,
            [EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId]
    FROM    [staging].[TEMPTeacherCandidateProgramAssociation] A
    FOR     XML PATH('TeacherCandidateTeacherPreparationProviderProgramAssociation') ,
                ROOT('InterchangeTeacherCandidate')                              
    DROP TABLE staging.TEMPTeacherCandidateProgramAssociation








GO


