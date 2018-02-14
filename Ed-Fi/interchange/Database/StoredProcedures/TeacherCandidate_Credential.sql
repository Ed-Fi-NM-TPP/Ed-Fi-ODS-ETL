IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'TeacherCandidate_Credential_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[TeacherCandidate_Credential_proc]
    END
 GO




CREATE PROCEDURE [mapping].[TeacherCandidate_Credential_proc]
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
                            AND TABLE_NAME = 'TEMPCredential' ) )
        BEGIN
            DROP TABLE staging.TEMPCredential
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPCredential
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY CredentialIdentifier ) AS RowNumber
              FROM      ( SELECT    CONVERT(VARCHAR(10), EXPIRATION_DATE, 126) AS 'ExpirationDate' ,
                                    CERT_AREA_DESC AS 'CredentialField/CodeValue' ,
                                    'http://www.ped.state.nm.us/Descriptor/CredentialFieldDescriptor.xml' AS 'CredentialField/Namespace' ,
                                    CERTIFICATE_NUMBER
                                    + CAST(CERT_TYPE_KEY AS NVARCHAR(30))
                                    + CAST(CERT_AREA_KEY AS NVARCHAR(30))
                                    + CAST(CERT_LEVEL_KEY AS NVARCHAR(30)) AS 'CredentialIdentifier' ,
                                    CONVERT(VARCHAR(10), EFFECTIVE_DATE, 126) AS 'IssuanceDate' ,
                                    'Licensure' AS 'CredentialType' ,
                                    'Postsecondary' AS 'GradeLevel/CodeValue' ,
                                    'http://ed-fi.org/Descriptor/GradeLevelDescriptor.xml' AS 'GradeLevel/Namespace' ,
                                    'NM' AS 'StateOfIssueStateAbbreviation' ,
                                    'Professional' AS 'TeachingCredential/CodeValue' ,
                                    'http://ed-fi.org/Descriptor/TeachingCredentialTypeDescriptor.xml' AS 'TeachingCredential/Namespace' ,
/************************************************************************************************************************************************
                                              Extension Fields 
**************************************************************************************************************************************************/
                                    'Actual' AS 'ValueType' ,
                                    CASE WHEN EPPCredential.CertificateGranted LIKE 'Yes'
                                         THEN 'true'
                                         ELSE 'false'
                                    END 'CertificateGranted' ,
                                    CASE WHEN EPPCredential.LicensureComplete LIKE 'Yes'
                                         THEN 'true'
                                         ELSE 'false'
                                    END AS 'LicensureComplete' ,
                                    CERT_LEVEL_DESC AS 'CertificationLevel' ,
                                    VerifyCredential.CERT_TYPE_DESC AS 'TypeOfCertification' ,
                                    VerifyCredential.CERT_TYPE_CAT AS 'CredentialCategory' ,
                                    CERT_STATUS AS 'CredentialStatus' ,
                                    ( SELECT    ( CASE WHEN EPPCredential.OtherMinor1 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.OtherMinor1
                                                  END ) AS 'OtherMinor' ,
                                                ( CASE WHEN EPPCredential.OtherMinor2 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.OtherMinor2
                                                  END ) AS 'OtherMinor' ,
                                                ( CASE WHEN EPPCredential.ProgramArea1 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.ProgramArea1
                                                  END ) AS 'ConcentrationArea' ,
                                                ( CASE WHEN EPPCredential.Program2Area LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.Program2Area
                                                  END ) AS 'ConcentrationArea' ,
                                                ( CASE WHEN EPPCredential.Program1SubjectArea1 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.Program1SubjectArea1
                                                  END ) AS 'PrimarySubjectArea' ,
                                                ( CASE WHEN EPPCredential.Program1SubjectArea2 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.Program1SubjectArea2
                                                  END ) AS 'PrimarySubjectArea' ,
                                                ( CASE WHEN EPPCredential.Program2SubjectArea LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.Program2SubjectArea
                                                  END ) AS 'SecondarySubjectArea' ,
                                                ( CASE WHEN EPPCredential.BilingualMinor1 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.BilingualMinor1
                                                  END ) AS 'BilingualMinor' ,
                                                ( CASE WHEN EPPCredential.BilingualMinor2 LIKE ''
                                                       THEN NULL
                                                       ELSE EPPCredential.BilingualMinor2
                                                  END ) AS 'BilingualMinor'
                                      FROM      staging.TeacherCandidates EPPCredential
                                      WHERE     VerifyCredential.TeacherCandidateIdentifier = EPPCredential.TeacherCandidateIdentifier
                                    FOR
                                      XML PATH('') ,
                                          TYPE
                                    ) AS ProgramInformation ,
                                    ROW_NUMBER() OVER ( PARTITION BY CERTIFICATE_NUMBER,
                                                        CERT_TYPE_KEY,
                                                        CERT_AREA_KEY,
                                                        CERT_LEVEL_KEY ORDER BY EXPIRATION_DATE DESC ) AS LatestCred
                          FROM      staging.Credential VerifyCredential
                                    INNER JOIN staging.TeacherCandidates EPPCredential ON EPPCredential.TeacherCandidateIdentifier = VerifyCredential.TeacherCandidateIdentifier
                        ) Cred
              WHERE     Cred.LatestCred = 1
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
 
  
    SELECT  [ExpirationDate] ,
            [CredentialField/CodeValue] ,
            [CredentialField/Namespace] ,
            [CredentialIdentifier] ,
            [IssuanceDate] ,
            [CredentialType] ,
            [GradeLevel/CodeValue] ,
            [GradeLevel/Namespace] ,
            [StateOfIssueStateAbbreviation] ,
            [TeachingCredential/CodeValue] ,
            [TeachingCredential/Namespace] ,
            [ValueType] ,
            [CertificateGranted] ,
            [LicensureComplete] ,
            [CertificationLevel] ,
            [TypeOfCertification] ,
            [CredentialCategory] ,
            [CredentialStatus] ,
            [ProgramInformation]
    FROM    [staging].[TEMPCredential]
    FOR     XML PATH('Credential') ,
                ROOT('InterchangeTeacherCandidate')
	                            
    DROP TABLE staging.TEMPCredential








GO


