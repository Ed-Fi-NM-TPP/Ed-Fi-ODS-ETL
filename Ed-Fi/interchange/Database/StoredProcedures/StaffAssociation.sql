IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'StaffAssociation_proc' )
    BEGIN
        DROP  PROCEDURE  [mapping].[StaffAssociation_proc]
    END
 GO



CREATE PROCEDURE [mapping].[StaffAssociation_proc]
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
                            AND TABLE_NAME = 'TEMPStaff' ) )
        BEGIN
            DROP TABLE staging.TEMPStaff
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPStaff
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY STAFF_ID ) RowNumber
              FROM      ( SELECT DISTINCT
                                    RIGHT(VWI.STAFF_ID, 5)
                                    + REPLACE(CAST(STAFF_BIRTHDATE AS DATE),
                                              '-', '') StaffUniqueId ,
                                    'Teacher' StaffClassification ,
                                    'Other' ProgramAssignment ,
                                    VWI.STAFF_ID ,
                                    S.ORIG_HIRE_DATE ,
                                    S.STAFF_BIRTHDATE ,
                                    S.STAFF_FIRST_NM ,
                                    S.STAFF_LAST_NM ,
                                    HISPANIC_IND
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] VWI
                                    JOIN ( SELECT DISTINCT
                                                    a.STAFF_ID ,
                                                    a.STAFF_BIRTHDATE ,
                                                    a.ORIG_HIRE_DATE ,
                                                    a.STAFF_FIRST_NM ,
                                                    a.STAFF_LAST_NM ,
                                                    COALESCE(HISPANIC_IND,
                                                             'No') HISPANIC_IND ,
                                                    DENSE_RANK() OVER ( PARTITION BY a.STAFF_ID ORDER BY B.SNAPSHOT_DATE DESC ) rowid
                                           FROM     staging.STAFF a
                                                    INNER JOIN staging.STAFF_SNAPSHOT
                                                    AS B ON B.STAFF_ID = a.STAFF_ID
                                                            AND B.ORIG_HIRE_DATE = a.ORIG_HIRE_DATE
                                           WHERE    STAFF_BIRTHDATE IS NOT NULL
                                            
										  
										   --AND STAFF_ID = '001668839' 
                                         ) S ON VWI.STAFF_ID = S.STAFF_ID
                          WHERE     rowid = 1
                                    AND STAFF_FIRST_NM IS NOT NULL
                                    AND S.STAFF_LAST_NM IS NOT NULL
                        ) a
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;

	--DECLARE @FileName NVARCHAR(1000) = 'StaffAssociation-2.0'+'_'+CAST(@iteration AS NVARCHAR(3));

    --SELECT  @result = ( 
	--INSERT INTO mapping.XMLData
	--SELECT @FileName,(
    SELECT  ( SELECT    ( SELECT DISTINCT
                                    S.StaffUniqueId AS StaffUniqueId
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    IdentificationCode ,
                                    IdentificationSystemDescriptor AS 'StaffIdentificationSystem/CodeValue' ,
                                    IdentificationCode AS AssigningOrganizationIdentificationCode
                          FROM      ( SELECT DISTINCT
                                                STAFF_ID ,
                                                CAST(RIGHT(a.STAFF_ID, 5) AS NVARCHAR(30)) Federal ,
                                                CAST(a.STAFF_ID AS NVARCHAR(30)) District ,
                                                CAST(a.STAFF_ID AS NVARCHAR(30)) School ,
                                                CAST([CERTIFICATE_NUMBER] AS NVARCHAR(30)) State ,
                                                CAST(t.TeacherID AS NVARCHAR(30)) AS Other ,
                                                CAST(TOS.LicenseNumber AS NVARCHAR(30)) [Professional Certificate]
                                      FROM      staging.STAFF a
                                                LEFT JOIN [staging].[STAFF_CERT_SNAPSHOT] B ON B.STAFF_KEY = a.STAFF_KEY
                                                              AND a.DISTRICT_KEY = B.DISTRICT_KEY
                                                LEFT JOIN staging.Teachers AS t ON t.ExternalStaffID = a.STAFF_ID
                                                LEFT JOIN staging.[TeacherObservationScores] TOS ON TOS.TeacherId = t.TeacherID
                                                              AND TOS.LicenseNumber = t.LicenseNumber
                                      WHERE     STAFF_BIRTHDATE IS NOT NULL
                                    ) pv UNPIVOT
											 ( IdentificationCode FOR IdentificationSystemDescriptor IN ( State,
                                                              Other,
                                                              [Professional Certificate],
                                                              Federal,
                                                              District, School ) ) unpv
                          WHERE     S.STAFF_ID = STAFF_ID
                        FOR
                          XML PATH('StaffIdentificationCode') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL 'PersonalTitlePrefix' ,
                                    S.STAFF_FIRST_NM FirstName ,
                                    NULL MiddleName ,
                                    S.STAFF_LAST_NM LastSurname ,
                                    NULL GenerationCodeSuffix ,
                                    NULL MaidenName
                        FOR
                          XML PATH('Name') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL AS Sex ,
                                    CAST(S.STAFF_BIRTHDATE AS DATE) BirthDate
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        --( SELECT DISTINCT
                        --            NULL StreetNumberName ,
                        --            NULL ApartmentRoomSuiteNumber ,
                        --            NULL BuildingSiteNumber ,
                        --            NULL City ,
                        --            NULL AS StateAbbreviation ,
                        --            NULL PostalCode ,
                        --            NULL NameOfCounty ,
                        --            NULL CountyFIPSCode ,
                        --            NULL Latitude ,
                        --            NULL Longitude ,
                        --            NULL BeginDate ,
                        --            NULL EndDate ,
                        --                                --CCT.Description AS NVARCHAR(50)) AS CountryCodeType ,                                                        
                        --            NULL AS AddressType
                        --FOR
                        --  XML PATH('Address') ,
                        --      TYPE
                        --) ,
                        --( SELECT DISTINCT
                        --            NULL AS TelephoneNumber ,
                        --            NULL AS TelephoneNumberType ,
                        --            NULL AS OrderOfPriority ,
                        --            NULL AS TextMessageCapabilityIndicator
                        --FOR
                        --  XML PATH('Telephone') ,
                        --      TYPE
                        --) ,
                        --( SELECT DISTINCT
                        --            NULL AS ElectronicMailAddress ,
                        --            NULL AS ElectronicMailType ,
                        --            NULL AS PrimaryEmailAddressIndicator
                        --FOR
                        --  XML PATH('ElectronicMail') ,
                        --      TYPE
                        --) ,
                        ( SELECT DISTINCT
                                    CASE WHEN UPPER(S.HISPANIC_IND) = 'NO'
                                         THEN 0
                                         ELSE 1
                                    END AS HispanicLatinoEthnicity ,
                                    NULL AS OldEthnicity
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL AS Race
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL AS 'Citizenship/CitizenshipStatus'
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        --( SELECT DISTINCT
                        --            NULL AS 'Language/CodeValue' ,
                        --            NULL AS LanguageUse
                        --FOR
                        --  XML PATH('Language') ,
                        --      TYPE
                        --) ,
                        ( SELECT DISTINCT
                                    NULL AS 'Citizenship/CitizenshipStatus'
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL AS 'HighestCompletedLevelOfEducation/CodeValue' ,
                                    NULL YearsOfPriorProfessionalExperience ,
                                    NULL YearsOfPriorTeachingExperience
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL LoginId ,
                                    NULL HighlyQualifiedTeacher
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    CredentialIdentifier AS 'CredentialIdentity/CredentialIdentifier' ,
                                    CAST(StateOfIssueStateAbbreviation AS NVARCHAR(50)) AS 'CredentialIdentity/StateOfIssueStateAbbreviation'
                          FROM      ( SELECT DISTINCT
                                                STAFF_ID ,
                                                CAST(CERTIFICATE_NUMBER AS NVARCHAR(10))
                                                + CAST(CERT_TYPE_KEY AS NVARCHAR(10))
                                                + CAST(CERT_AREA_KEY AS NVARCHAR(10))
                                                + CAST(CERT_LEVEL_KEY AS NVARCHAR(10)) CredentialIdentifier ,
                                                'NM' StateOfIssueStateAbbreviation
                                      FROM      staging.Credential
                                      WHERE     SCHOOL_YEAR = 2017
                                    ) AS C
                          WHERE     C.STAFF_ID = S.STAFF_ID
                        FOR
                          XML PATH('CredentialReference') ,
                              TYPE
                        ) ,
                        ( SELECT    CAST(YEAR(abc.YearEnding) AS NVARCHAR(4)) AS 'EvaluationSchoolYear' ,
                                    CAST(AttendanceScore AS DECIMAL(18, 4)) 'AttendanceScore' ,
                                    CAST(D1D4TotalScore AS DECIMAL(18, 4)) 'ProfessionalismScore' ,
                                    CAST(D2D3TotalScore AS DECIMAL(18, 4)) 'ClassroomObservationScore' ,
                                    CAST(EvaluationTotalPoints AS DECIMAL(18,
                                                              4)) 'TotalEvalPoints' ,
                                    CAST(MultipleMeasure3Points
                                    / CASE WHEN MultipleMeasure3PossiblePoints = 0
                                           THEN 1
                                           ELSE MultipleMeasure3PossiblePoints
                                      END AS DECIMAL(18, 4)) 'SurveyScore' ,
                                    CAST(NumberOfDaysAbsent AS DECIMAL(18, 4)) 'NumberDaysAbsent' ,
                                    NumberOfLocations 'NumberLocations' ,
                                    SurveyType 'TypeOfSurvey' ,
                                    ( SELECT DISTINCT
                                                TV.CurrentYear AS 'YearOfAssessment' ,
                                                AssessmentSubtestGroupName 'AssessmentSubtestGroup' ,
                                                TotalNumStudentsCurrentYear 'TotalNumberStudents' ,
                                                CAST(TotalVASOverall AS DECIMAL(18,
                                                              4)) 'VASOverallScore'
                                      FROM      staging.TeacherValueAddedTests TV
                                      WHERE     TV.TeacherID = abc.TeacherId
                                                AND TV.AssessmentSubtestGroupName IS NOT NULL
                                                AND TV.CurrentYear IS NOT NULL
                                                AND TotalNumStudentsCurrentYear IS NOT NULL
                                                AND TotalVASOverall IS NOT NULL
                                    FOR
                                      XML PATH('VASResult') ,
                                          TYPE
                                    ) ,
                                    Rating 'EffectivenessRating' ,
                                    CAST(StudentAchievement1Points
                                    / CASE WHEN StudentAchievement1PossiblePoints = 0.0
                                           THEN 1.0
                                           ELSE StudentAchievement1PossiblePoints
                                      END AS DECIMAL(18, 4)) 'ValueAdd'
                          FROM      ( SELECT DISTINCT
                                                S.STAFF_ID ,
                                                TOS.TeacherId ,
                                                TOS.D1D4TotalScore ,
                                                TOS.D2D3TotalScore ,
                                                TE.EvaluationTotalPoints ,
                                                TE.MultipleMeasure3Points ,
                                                TE.MultipleMeasure3PossiblePoints ,
                                                AO.NumberOfDaysAbsent ,
                                                AO.NumberOfLocations ,
                                                'Student' SurveyType ,
                                                TE.Rating ,
                                                AO.score AttendanceScore ,
                                                StudentAchievement1Points ,
                                                StudentAchievement1PossiblePoints ,
                                                TE.YearEnding
                                      FROM      staging.[TeacherObservationScores] TOS
                                                JOIN staging.Teachers T ON T.TeacherID = TOS.TeacherID
                                                JOIN staging.STAFF S ON S.STAFF_ID = T.ExternalStaffID
                                                JOIN staging.TeacherEvaluationsV3 TE ON TE.TeacherID = T.TeacherID
                                                LEFT JOIN [staging].[TeacherAttendanceScore] AO ON S.STAFF_ID = AO.ExternalStaffID
                                    ) abc
                          WHERE     abc.STAFF_ID = S.STAFF_ID
                        FOR
                          XML PATH('EvaluationInformation') ,
                              TYPE
                        )
              FROM      ( SELECT    StaffUniqueId ,
                                    STAFF_ID ,
                                    STAFF_BIRTHDATE ,
                                    STAFF_FIRST_NM ,
                                    STAFF_LAST_NM ,
                                    HISPANIC_IND ,
                                    CurrDate
                          FROM      staging.TEMPStaff
                        ) AS S
            FOR
              XML PATH('Staff') ,
                  TYPE
            ) ,
		--------------------------------EdorgEmployment
            --( SELECT    ( SELECT    NULL AS 'StaffReference/StaffIdentity/StaffUniqueId' ,
            --                        NULL AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            --                        NULL AS 'EmploymentStatus/CodeValue'
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    NULL HireDate ,
            --                        NULL EndDate ,
            --                        NULL AS Separation ,
            --                        NULL AS 'SeparationReason/CodeValue'
            --            FOR
            --              XML PATH('EmploymentPeriod') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    NULL Department ,
            --                        NULL FullTimeEquivalency ,
            --                        NULL OfferDate ,
            --                        NULL HourlyWage
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            )
             
            --FOR
            --  XML PATH('StaffEducationOrganizationEmploymentAssociation') ,
            --      TYPE
            --) ,
            ( SELECT   DISTINCT
                        SEO.StaffUniqueId AS 'StaffReference/StaffIdentity/StaffUniqueId' ,
                        SSA.[LOCATION_ID] AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        SEO.StaffClassification AS 'StaffClassification/CodeValue' ,
                        NULL PositionTitle ,
                        CAST(COALESCE(ORIG_HIRE_DATE, '01/01/1900') AS DATE) BeginDate ,
                        NULL EndDate ,
                        NULL OrderOfAssignment
               
                        --( SELECT    ( SELECT DISTINCT
                        --                        NULL AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        --                        NULL AS 'StaffReference/StaffIdentity/StaffUniqueId' ,
                        --                        NULL AS 'EmploymentStatus/CodeValue' ,
                        --                        NULL AS 'HireDate'
                        --            FOR
                        --              XML PATH('StaffEducationOrganizationEmploymentAssociationIdentity') ,
                        --                  TYPE
                        --            )
                        --FOR
                        --  XML PATH('StaffEducationOrganizationEmploymentAssociationReference') ,
                        --      TYPE
                        --)
              FROM      staging.TEMPStaff SEO
                        INNER JOIN staging.StaffSchoolAssociation SSA ON SSA.STAFF_ID = SEO.STAFF_ID
                        INNER JOIN staging.LOCATION_YEAR LY ON LY.LOCATION_ID = SSA.LOCATION_ID
            FOR
              XML PATH('StaffEducationOrganizationAssignmentAssociation') ,
                  TYPE
            ) ,
            ( SELECT    A.StaffUniqueId AS 'StaffReference/StaffIdentity/StaffUniqueId' ,
                        A.LOCATION_ID AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        CAST(SCHOOL_YEAR - 1 AS NVARCHAR(4)) + '-'
                        + CAST(SCHOOL_YEAR AS NVARCHAR) SchoolYear ,
                        CAST(ProgramAssignment AS NVARCHAR(50)) AS 'ProgramAssignment/CodeValue' ,
                        ( SELECT DISTINCT
                                    CASE g.GradeLevel
                                      WHEN 'PK'
                                      THEN 'Preschool/Prekindergarten'
                                      WHEN 'KN' THEN 'Kindergarten'
                                      WHEN '01' THEN 'First grade'
                                      WHEN '02' THEN 'Second grade'
                                      WHEN '03' THEN 'Third grade'
                                      WHEN '04' THEN 'Fourth grade'
                                      WHEN '05' THEN 'Fifth grade'
                                      WHEN '06' THEN 'Sixth grade'
                                      WHEN '07' THEN 'Seventh grade'
                                      WHEN '08' THEN 'Eighth grade'
                                      WHEN '09' THEN 'Ninth grade'
                                      WHEN '10' THEN 'Tenth grade'
                                      WHEN '11' THEN 'Eleventh grade'
                                      WHEN '12' THEN 'Twelfth grade'
                                    END CodeValue
                          FROM      staging.StaffSchoolAssociation SSA
                                    INNER JOIN staging.TEMPStaff TSASS ON SSA.STAFF_ID = TSASS.STAFF_ID
                                    INNER JOIN ( SELECT DISTINCT
                                                        [MIN_GRADE_LVL_CD] GradeLevel ,
                                                        CASE WHEN [MIN_GRADE_LVL_CD] = 'PK'
                                                             THEN -1
                                                             WHEN [MIN_GRADE_LVL_CD] = 'KN'
                                                             THEN 0
                                                             ELSE CAST([MIN_GRADE_LVL_CD] AS INT)
                                                        END ID
                                                 FROM   [staging].[STATE_COURSE]
                                                 WHERE  [MIN_GRADE_LVL_CD] IS NOT NULL
                                                 UNION
                                                 SELECT DISTINCT
                                                        [MAX_GRADE_LVL_CD] GradeLevel ,
                                                        CASE WHEN [MAX_GRADE_LVL_CD] = 'PK'
                                                             THEN -1
                                                             WHEN [MAX_GRADE_LVL_CD] = 'KN'
                                                             THEN 0
                                                             ELSE CAST([MAX_GRADE_LVL_CD] AS INT)
                                                        END ID
                                                 FROM   [staging].[STATE_COURSE]
                                                 WHERE  [MAX_GRADE_LVL_CD] IS NOT NULL
                                               ) g ON g.ID BETWEEN SSA.[MIN_GRADE_LVL_CD]
                                                           AND
                                                              SSA.[MAX_GRADE_LVL_CD]
                          WHERE     SSA.STAFF_ID = A.STAFF_ID
                        FOR
                          XML PATH('GradeLevel') ,
                              TYPE
                        )
              FROM      ( SELECT DISTINCT
                                    A.StaffUniqueId ,
                                    B.STAFF_ID ,
                                    B.LOCATION_ID ,
                                    A.ProgramAssignment ,
                                    B.SCHOOL_YEAR ,
                                    ROW_NUMBER() OVER ( PARTITION BY A.STAFF_ID,
                                                        ly.LOCATION_ID,
                                                        B.SCHOOL_YEAR ORDER BY B.SCHOOL_YEAR ) RowNumber
                          FROM      staging.TEMPStaff A
                                    INNER JOIN staging.StaffSchoolAssociation B ON B.STAFF_ID = A.STAFF_ID
                                    INNER JOIN staging.LOCATION_YEAR ly ON ly.LOCATION_ID = B.LOCATION_ID
                        ) A
              WHERE     A.RowNumber = 1
            FOR
              XML PATH('StaffSchoolAssociation') ,
                  TYPE
            ) 
            --( SELECT    ( SELECT DISTINCT
            --                        NULL AS 'StaffReference/StaffIdentity/StaffUniqueId'
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    ( SELECT DISTINCT
            --                                    NULL AS 'LocationIdentity/ClassroomIdentificationCode' ,
            --                                    NULL AS 'LocationIdentity/SchoolReference/SchoolIdentity/SchoolId'
            --                        FOR
            --                          XML PATH('LocationReference') ,
            --                              TYPE
            --                        ) ,
            --                        ( SELECT DISTINCT
            --                                    NULL 'ClassPeriodIdentity/ClassPeriodName' ,
            --                                    NULL AS 'ClassPeriodIdentity/SchoolReference/SchoolIdentity/SchoolId'
            --                        FOR
            --                          XML PATH('ClassPeriodReference') ,
            --                              TYPE
            --                        ) ,
            --                        ( SELECT DISTINCT
            --                                    NULL AS 'CourseOfferingIdentity/LocalCourseCode' ,
            --                                    NULL AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
            --                                    NULL AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/SchoolYear' ,
            --                                    NULL AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/Term/CodeValue' ,
            --                                    NULL AS 'CourseOfferingIdentity/SchoolReference/SchoolIdentity/SchoolId'
            --                        FOR
            --                          XML PATH('CourseOfferingReference') ,
            --                              TYPE
            --                        ) ,
            --                        ( SELECT DISTINCT
            --                                    NULL UniqueSectionCode ,
            --                                    NULL SequenceOfCourse
            --                        FOR
            --                          XML PATH('') ,
            --                              TYPE
            --                        )
            --            FOR
            --              XML PATH('SectionIdentity') ,
            --                  ROOT('SectionReference') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT DISTINCT
            --                        NULL AS 'ClassroomPosition/CodeValue' ,
            --                        NULL BeginDate ,
            --                        NULL EndDate ,
            --                        NULL HighlyQualifiedTeacher
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            )
            --FOR
            --  XML PATH('StaffSectionAssociation') ,
            --      TYPE
            --) ,
            --( SELECT  DISTINCT
            --            NULL EventDate ,
            --            NULL AS LeaveEventCategory ,
            --            NULL LeaveEventReason ,
            --            NULL HoursOnLeave ,
            --            NULL SubstituteAssigned ,
            --            NULL 'StaffReference/StaffIdentity/StaffUniqueId'
            --FOR
            --  XML PATH('LeaveEvent') ,
            --      TYPE
            --) ,
            --( SELECT    ( SELECT DISTINCT
            --                        NULL AS 'EmploymentStatus/CodeValue' ,
            --                        NULL AS 'StaffClassification/CodeValue' ,
            --                        NULL PositionTitle ,
            --                        NULL RequisitionNumber ,
            --                        NULL AS 'ProgramAssignment/CodeValue'
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT  DISTINCT
            --                        NULL AS CodeValue
                        
            --            FOR
            --              XML PATH('InstructionalGradeLevel') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    NULL CodeValue
                         
            --            FOR
            --              XML PATH('AcademicSubject') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    NULL DatePosted ,
            --                        NULL DatePostingRemoved ,
            --                        NULL AS PostingResult ,
            --                        NULL AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId'
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            )
            --FOR
            --  XML PATH('OpenStaffPosition') ,
            --      TYPE
            --) ,
            --( SELECT    NULL 'StaffReference/StaffIdentity/StaffUniqueId' ,
            --            NULL AS 'ProgramReference/ProgramIdentity/ProgramType' ,
            --            NULL 'ProgramReference/ProgramIdentity/ProgramName' ,
            --            NULL AS 'ProgramReference/ProgramIdentity/EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            --            NULL BeginDate ,
            --            NULL EndDate ,
            --            NULL StudentRecordAccess
            --FOR
            --  XML PATH('StaffProgramAssociation') ,
            --      TYPE
            --)
            ,
            ( SELECT DISTINCT
                        [ExpirationDate] ,
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
                        [CredentialStatus] --,
                        --[ProgramInformation/OtherMinor1] AS 'ProgramInformation/OtherMinor' ,
                        --[ProgramInformation/OtherMinor2] AS 'ProgramInformation/OtherMinor' ,
                        --[ProgramInformation/ConcentrationArea1] AS 'ProgramInformation/ConcentrationArea' ,
                        --[ProgramInformation/ConcentrationArea2] AS 'ProgramInformation/ConcentrationArea' ,
                        --[ProgramInformation/PrimarySubjectArea1] AS 'ProgramInformation/PrimarySubjectArea' ,
                        --[ProgramInformation/PrimarySubjectArea2] AS 'ProgramInformation/PrimarySubjectArea' ,
                        --[ProgramInformation/SecondarySubjectArea] ,
                        --[ProgramInformation/BilingualMinor1] AS 'ProgramInformation/BilingualMinor' ,
                        --[ProgramInformation/BilingualMinor2] AS 'ProgramInformation/BilingualMinor'
              FROM      ( SELECT  DISTINCT
                                    CONVERT(VARCHAR(10), EXPIRATION_DATE, 126) AS 'ExpirationDate' ,
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
                                    END AS 'CertificateGranted' ,
                                    CASE WHEN EPPCredential.LicensureComplete LIKE 'Yes'
                                         THEN 'true'
                                         ELSE 'false'
                                    END AS 'LicensureComplete' ,
                                    CERT_LEVEL_DESC AS 'CertificationLevel' ,
                                    VerifyCredential.CERT_TYPE_DESC AS 'TypeOfCertification' ,
                                    VerifyCredential.CERT_TYPE_CAT AS 'CredentialCategory' ,
                                    CERT_STATUS AS 'CredentialStatus' ,
                                    --EPPCredential.OtherMinor1 AS 'ProgramInformation/OtherMinor1' ,
                                    --EPPCredential.OtherMinor2 AS 'ProgramInformation/OtherMinor2' ,
                                    --EPPCredential.ProgramArea1 AS 'ProgramInformation/ConcentrationArea1' ,
                                    --EPPCredential.Program2Area AS 'ProgramInformation/ConcentrationArea2' ,
                                    --EPPCredential.Program1SubjectArea1 AS 'ProgramInformation/PrimarySubjectArea1' ,
                                    --EPPCredential.Program1SubjectArea2 AS 'ProgramInformation/PrimarySubjectArea2' ,
                                    --EPPCredential.Program2SubjectArea AS 'ProgramInformation/SecondarySubjectArea' ,
                                    --EPPCredential.BilingualMinor1 AS 'ProgramInformation/BilingualMinor1' ,
                                    --EPPCredential.BilingualMinor2 AS 'ProgramInformation/BilingualMinor2' ,
                                    ROW_NUMBER() OVER ( PARTITION BY CERTIFICATE_NUMBER,
                                                        CERT_TYPE_KEY,
                                                        CERT_AREA_KEY,
                                                        CERT_LEVEL_KEY ORDER BY EXPIRATION_DATE DESC ) AS LatestCred
                          FROM      staging.Credential VerifyCredential
                                    INNER JOIN staging.TEMPStaff Staff ON Staff.STAFF_ID = VerifyCredential.STAFF_ID
                                    LEFT JOIN staging.TeacherCandidates EPPCredential ON VerifyCredential.TeacherCandidateIdentifier = EPPCredential.TeacherCandidateIdentifier
                          WHERE     VerifyCredential.SCHOOL_YEAR = 2017
                        ) Cred
              WHERE     Cred.LatestCred = 1
            FOR
              XML PATH('Credential') ,
                  TYPE
            ) ,
            ( SELECT    StaffUniqueId AS 'StaffReference/StaffIdentity/StaffUniqueId' ,
                        [LOCATION_ID] AS 'SectionReference/SectionIdentity/LocationReference/LocationIdentity/ClassroomIdentificationCode' ,
                        LOCATION_ID AS 'SectionReference/SectionIdentity/LocationReference/LocationIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
                        1 AS 'SectionReference/SectionIdentity/ClassPeriodReference/ClassPeriodIdentity/ClassPeriodName' ,
                        LOCATION_ID AS 'SectionReference/SectionIdentity/ClassPeriodReference/ClassPeriodIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
                        ( SELECT DISTINCT
                                    [COURSE_ID] AS 'CourseOfferingIdentity/LocalCourseCode' ,
                                    LOCATION_ID AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
                                    CAST(SCHOOL_YEAR - 1 AS NVARCHAR(4)) + '-'
                                    + CAST(SCHOOL_YEAR AS NVARCHAR(4)) AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/SchoolYear' ,
                                    'Other' AS 'CourseOfferingIdentity/SessionReference/SessionIdentity/Term/CodeValue' ,
                                    LOCATION_ID AS 'CourseOfferingIdentity/SchoolReference/SchoolIdentity/SchoolId'
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] B
                          WHERE     A.STAFF_ID = A.STAFF_ID
                                    AND A.LOCATION_ID = B.LOCATION_ID
                                    AND A.COURSE_ID = B.COURSE_ID
                                    AND A.SECTION_CODE = B.SECTION_CODE
                                    AND A.SCHOOL_YEAR = B.SCHOOL_YEAR
                        FOR
                          XML PATH('CourseOfferingReference') ,
                              TYPE
                        ) AS 'SectionReference/SectionIdentity' ,
                        [SECTION_CODE] AS 'SectionReference/SectionIdentity/UniqueSectionCode' ,
                        1 AS 'SectionReference/SectionIdentity/SequenceOfCourse' ,
                        'Other' AS 'ClassroomPosition/CodeValue' ,
                        'http://exchange.ed-fi.org/TPDP/Descriptor/ClassroomPositionDescriptor.xml' AS 'ClassroomPosition/Namespace'
              FROM      ( SELECT  DISTINCT
                                    A.STAFF_ID ,
                                    D.LOCATION_ID ,
                                    SECTION_CODE ,
                                    D.SCHOOL_YEAR ,
                                    COURSE_ID ,
                                    StaffUniqueId
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] A
                                    INNER JOIN staging.TEMPStaff C ON C.STAFF_ID = A.STAFF_ID
                                    INNER JOIN staging.LOCATION_YEAR D ON D.LOCATION_ID = A.LOCATION_ID
                                                              AND D.SCHOOL_YEAR = A.SCHOOL_YEAR
                          WHERE     A.SCHOOL_YEAR >= 2010
                        ) A
            FOR
              XML PATH('StaffSectionAssociation') ,
                  TYPE
            )
    FOR     XML PATH('InterchangeStaffAssociation')

	--) xmldata
    --                  );

    --SET @result_new = REPLACE(CAST(@result AS VARCHAR(MAX)),
    --                          '<InterchangeStaffAssociation>',
    --                          '<InterchangeStaffAssociation xmlns="http://ed-fi.org/0200" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ed-fi.org/0200 D:\GitHub\Carlos\2.0Schemas\Interchange-StaffAssociation.xsd"> ');


    ----SELECT  @result_new
    ----FOR     XML PATH('');
    DROP TABLE staging.TEMPStaff







































GO


