
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_TeacherCandidate_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_TeacherCandidate_proc]
    END
 GO


CREATE PROCEDURE [mapping].[TeacherCandidate_TeacherCandidate_proc]
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
                            AND TABLE_NAME = 'TEMPTeacherCandidates' ) )
        BEGIN
            DROP TABLE staging.TEMPTeacherCandidates
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPTeacherCandidates
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY TeacherCandidates.TeacherCandidateIdentifier ) RowNumber
              FROM      ( SELECT DISTINCT
                                    TeacherCandidateIdentifier AS 'TeacherCandidateIdentifier' ,
                                    TeacherCandidates.FirstName AS 'Name/FirstName' ,
                                    TeacherCandidates.MiddleName AS 'Name/MiddleName' ,
                                    TeacherCandidates.LastSurname AS 'Name/LastSurname' ,
                                    CASE WHEN TeacherCandidates.Gender LIKE 'M%'
                                         THEN 'Male'
                                         WHEN TeacherCandidates.Gender LIKE 'F%'
                                         THEN 'Female'
                                         ELSE 'Not Selected'
                                    END AS 'Sex' ,
                                    CONVERT(CHAR(10), TeacherCandidates.BirthDate, 126) AS 'BirthData/BirthDate' ,
                                    CASE WHEN TeacherCandidates.NMEthnicity = 'Hispanic'
                                         THEN 'true'
                                         ELSE 'false'
                                    END HispanicLatinoEthnicity ,
                                    TeacherCandidateIdentifier AS 'StudentReference/StudentIdentity/StudentUniqueId' , 

										

		/*********************************************************************************************************************
		             Extension 
		**************************************************************************************/
                                    TeacherCandidates.NMEthnicity AS 'NMEthnicity' ,
                                    TeacherCandidates.ACTScore AS 'ACTScore' ,
                                    TeacherCandidates.SATScore AS 'SATScore'
                          FROM      staging.TeacherCandidates AS TeacherCandidates
                          WHERE     TeacherCandidates.SSN IS NOT NULL
           --                                 AND TeacherCandidates.BirthDate IS NOT NULL
           --                                 AND TeacherCandidates.StartMonth IS NOT NULL
           --                                 AND TeacherCandidates.StartYear IS NOT NULL 
                                    AND TeacherCandidates.NMEthnicity IS NOT NULL
                        ) TeacherCandidates
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    

    SELECT  [TeacherCandidateIdentifier] ,
            ( SELECT DISTINCT
                        SSN 'IdentificationCode' ,
                        'SSN' AS 'StudentIdentificationSystem/CodeValue' ,
                        'http://ed-fi.org/Descriptor/StudentIdentificationSystemDescriptor.xml' 'StudentIdentificationSystem/Namespace' ,
                        EducationOrganizationId AS 'AssigningOrganizationIdentificationCode'
              FROM      staging.TeacherCandidateTeacherPreparationProviderAssociation
                        AS tctppa
              WHERE     tctppa.TeacherCandidateIdentifier = TeacherCandidates.TeacherCandidateIdentifier
            FOR
              XML PATH('TeacherCandidateIdentificationCode') ,
                  TYPE
            ) ,
            [Name/FirstName] ,
            [Name/MiddleName] ,
            [Name/LastSurname] ,
            [Sex] ,
            [BirthData/BirthDate] ,
            [HispanicLatinoEthnicity] ,
            ( SELECT   DISTINCT
                        cred.CredentialIdentifier AS 'CredentialIdentity/CredentialIdentifier' ,
                        'NM' AS 'CredentialIdentity/StateOfIssueStateAbbreviation'
              FROM      staging.Credential cred
              WHERE     cred.TeacherCandidateIdentifier = TeacherCandidates.TeacherCandidateIdentifier
            FOR
              XML PATH('CredentialReference') ,
                  TYPE
            ) ,
            [StudentReference/StudentIdentity/StudentUniqueId] ,
            [NMEthnicity] ,
            [ACTScore] ,
            [SATScore]
    FROM    [staging].[TEMPTeacherCandidates] TeacherCandidates
    FOR     XML PATH('TeacherCandidate') ,
                ROOT('InterchangeTeacherCandidate')
                              
    DROP TABLE staging.TEMPTeacherCandidates






GO


