
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'EducationOrganization_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[EducationOrganization_proc]
    END
 GO


CREATE PROCEDURE [mapping].[EducationOrganization_proc]
    (
      @iteration INT = 0 ,
      @maxRecords INT = 300000
    )
AS
    DECLARE @result XML;

    DECLARE @result_new XML;

    DECLARE @startRow INT = ( @maxRecords * @iteration ) + 1

    DECLARE @endRow INT = ( @maxRecords * @iteration ) + @maxRecords

    IF ( EXISTS ( SELECT    *
                  FROM      INFORMATION_SCHEMA.TABLES
                  WHERE     TABLE_SCHEMA = 'staging'
                            AND TABLE_NAME = 'TEMPEdOrgCourses' ) )
        BEGIN
            DROP TABLE staging.TEMPEdOrgCourses
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPEdOrgCourses
    FROM    ( SELECT    [LOCATION_ID] ,
                        [NumberOfParts] ,
                        ORG_TYPE_LONG ,
                        SCHOOL_TYPE_DESC ,
                        ROW_NUMBER() OVER ( ORDER BY vci.LOCATION_ID ) RowNumber
              FROM      ( SELECT DISTINCT
                                    a.[LOCATION_ID] ,
                                    1 [NumberOfParts] ,
                                    ORG_TYPE_LONG ,
                                    SCHOOL_TYPE_DESC
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] a
                                    JOIN staging.LOCATION_YEAR LY ON a.LOCATION_KEY = LY.LOCATION_KEY
                                                              AND a.SCHOOL_YEAR = LY.SCHOOL_YEAR
                        ) vci
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;

	--DECLARE @FileName NVARCHAR(1000) = 'EducationOrganization-2.0'+'_'+CAST(@iteration AS NVARCHAR(3));

    --SELECT  @result = ( 
	--INSERT INTO mapping.XMLData
	--SELECT @FileName,(
    SELECT  ( SELECT    ( SELECT DISTINCT
                                    StateOrganizationId StateOrganizationId ,
                                    NameOfInstitution NameOfInstitution ,
                                    ShortNameOfInstitution ShortNameOfInstitution ,
                                    EducationOrganizationCategory EducationOrganizationCategory
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    '300 Don Gaspar' StreetNumberName ,
                                    NULL ApartmentRoomSuiteNumber ,
                                    NULL BuildingSiteNumber ,
                                    'Santa Fe' City ,
                                    'NM' StateAbbreviation ,
                                    '87501' PostalCode ,
                                    NULL NameOfCounty ,
                                    NULL CountyFIPSCode ,
                                    NULL Latitude ,
                                    NULL Longitude ,
                                    NULL BeginDate ,
                                    NULL EndDate ,
                                    'Physical' AddressType
                        FOR
                          XML PATH('Address') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL WebSite ,
                                    NULL OperationalStatus ,
                                    StateEducationAgencyId StateEducationAgencyId
                        FOR
                          XML PATH('') ,
                              TYPE
                        )
              FROM      ( SELECT    a.*
                          FROM      ( SELECT    'NMPED555' StateOrganizationId ,
                                                '5000005' StateEducationAgencyId ,
                                                'New Mexico Public Education Department' NameOfInstitution ,
                                                'NMPED' ShortNameOfInstitution ,
                                                'State Education Agency' EducationOrganizationCategory ,
                                                1 RowNumber
                                      UNION
                                      SELECT    'NMEPP101' StateOrganizationId ,
                                                '1001' StateEducationAgencyId ,
                                                'New Mexico EPPs' NameOfInstitution ,
                                                'NMEPPs' ShortNameOfInstitution ,
                                                'State Education Agency' EducationOrganizationCategory ,
                                                2 RowNumber
                                    ) a
                          --WHERE     RowNumber BETWEEN @startRow AND @endRow
                        ) SEA
            FOR
              XML PATH('StateEducationAgency') ,
                  TYPE
            ) ,
           -- ( SELECT    ( SELECT DISTINCT
           --                         ESC.EducationServiceCenterId AS StateOrganizationId ,
           --                         EO.NameOfInstitution ,
           --                         EO.ShortNameOfInstitution ,
           --                         EOCT.OrganizationCategory AS EducationOrganizationCategory
           --             FOR
           --               XML PATH('') ,
           --                   TYPE
           --             ) ,
           --             ( SELECT DISTINCT
           --                         EOAdd.StreetNumberName ,
           --                         EOAdd.ApartmentRoomSuiteNumber ,
           --                         EOAdd.BuildingSiteNumber ,
           --                         EOAdd.City ,
           --                         SAT.CodeValue AS StateAbbreviation ,
           --                         EOAdd.PostalCode ,
           --                         EOAdd.NameOfCounty ,
           --                         EOAdd.CountyFIPSCode ,
           --                         EOAdd.Latitude ,
           --                         EOAdd.Longitude ,
           --                         EOAdd.BeginDate ,
           --                         EOAdd.EndDate ,
           --                         AT.CodeValue AS AddressType
           --               FROM      edfi.EducationOrganizationAddress EOAdd
           --                         JOIN edfi.AddressType AT ON EOAdd.AddressTypeId = AT.AddressTypeId
           --                         JOIN edfi.StateAbbreviationType SAT ON EOAdd.StateAbbreviationTypeId = SAT.StateAbbreviationTypeId
           --               WHERE     ESC.EducationServiceCenterId = EOAdd.EducationOrganizationId
           --             FOR
           --               XML PATH('Address') ,
           --                   TYPE
           --             ) ,
           --             ( SELECT DISTINCT
           --                         EO.WebSite ,
           --                         OST.CodeValue AS OperationalStatus ,
           --                         ESC.EducationServiceCenterId
           --             FOR
           --               XML PATH('') ,
           --                   TYPE
           --             )
           --   FROM      ( SELECT    a.*
           --               FROM      ( SELECT    TSSAE.* ,
           --                                     ROW_NUMBER() OVER ( ORDER BY TSSAE.EducationServiceCenterId ) RowNumber
           --                           FROM      edfi.EducationServiceCenter TSSAE
           --                         ) a
           --               WHERE     RowNumber BETWEEN @startRow AND @endRow
           --             ) ESC
           --             LEFT OUTER JOIN edfi.EducationOrganization EO ON EO.EducationOrganizationId = ESC.EducationServiceCenterId
           --             LEFT OUTER JOIN edfi.EducationOrganizationCategory EOC ON ESC.EducationServiceCenterId = EOC.EducationOrganizationId
           --             LEFT OUTER JOIN edfi.EducationOrganizationCategoryType EOCT ON EOC.EducationOrganizationCategoryTypeId = EOCT.EducationOrganizationCategoryTypeId
           --             LEFT OUTER JOIN edfi.OperationalStatusType OST ON EO.OperationalStatusTypeId = OST.OperationalStatusTypeId
											----WHERE EO.EducationOrganizationId = '792'
           -- FOR
           --   XML PATH('EducationServiceCenter') ,
           --       TYPE
           -- ) ,
            ( SELECT    ( SELECT DISTINCT
                                    LocalEducationAgencyId StateOrganizationId ,
                                    NameOfInstitution NameOfInstitution ,
                                    NameOfInstitution ShortNameOfInstitution ,
                                    EducationOrganizationCategory EducationOrganizationCategory
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    '300 Don Gaspar' StreetNumberName ,
                                    NULL ApartmentRoomSuiteNumber ,
                                    NULL BuildingSiteNumber ,
                                    'Santa Fe' City ,
                                    'NM' StateAbbreviation ,
                                    '87501' PostalCode ,
                                    NULL NameOfCounty ,
                                    NULL CountyFIPSCode ,
                                    NULL Latitude ,
                                    NULL Longitude ,
                                    NULL BeginDate ,
                                    NULL EndDate ,
                                    'Physical' AddressType
                        FOR
                          XML PATH('Address') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL WebSite ,
                                    NULL AS OperationalStatus ,
                                    LocalEducationAgencyId ,
                                    LocalEducationAgencyCategory AS LocalEducationAgencyCategory
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        --( SELECT DISTINCT
                        --            EducationServiceCenterId AS 'EducationServiceCenterReference/EducationServiceCenterIdentity/EducationServiceCenterId'
                        --  FROM      edfi.EducationServiceCenter ESC
                        --  WHERE     ESC.EducationServiceCenterId = LEA.EducationServiceCenterId
                        --FOR
                        --  XML PATH('') ,
                        --      TYPE
                        --) ,
                        ( SELECT DISTINCT
                                    StateOrganizationId AS 'StateEducationAgencyReference/StateEducationAgencyIdentity/StateEducationAgencyId'
                        FOR
                          XML PATH('') ,
                              TYPE
                        )
              FROM      ( SELECT    a.*
                          FROM      ( SELECT    *
                                      FROM      ( SELECT DISTINCT
                                                            DISTRICT_NAME NameOfInstitution ,
                                                            DISTRICT_CODE LocalEducationAgencyId ,
                                                            '5000005' StateOrganizationId ,
                                                            'Local Education Agency' EducationOrganizationCategory ,
                                                            'Independent' LocalEducationAgencyCategory
                                                  FROM      [staging].LOCATION_YEAR a
                                                ) aa
                                    ) a
                        ) LEA
            FOR
              XML PATH('LocalEducationAgency') ,
                  TYPE
            ) ,
            ( SELECT    ( SELECT DISTINCT
                                    S.SchoolId AS StateOrganizationId ,
                                    NameOfInstitution ,
                                    NameOfInstitution ShortNameOfInstitution ,
                                    EducationOrganizationCategory AS EducationOrganizationCategory
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    '300 Don Gaspar' StreetNumberName ,
                                    NULL ApartmentRoomSuiteNumber ,
                                    NULL BuildingSiteNumber ,
                                    'Santa Fe' City ,
                                    'NM' StateAbbreviation ,
                                    '87501' PostalCode ,
                                    NULL NameOfCounty ,
                                    NULL CountyFIPSCode ,
                                    NULL Latitude ,
                                    NULL Longitude ,
                                    NULL BeginDate ,
                                    NULL EndDate ,
                                    'Physical' AddressType
                        FOR
                          XML PATH('Address') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL WebSite ,
                                    OperationalStatus AS OperationalStatus ,
                                    S.SchoolId
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    CASE B.GradeLevel
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
                                    END AS 'GradeLevel/CodeValue'
                          FROM      ( SELECT    LOCATION_ID ,
                                                CASE WHEN [MIN_GRADE_LVL_CD] = 'PK'
                                                     THEN -1
                                                     WHEN [MIN_GRADE_LVL_CD] = 'KN'
                                                     THEN 0
                                                     ELSE CAST([MIN_GRADE_LVL_CD] AS INT)
                                                END MIN_GRADE_LVL_CD ,
                                                CASE WHEN [MAX_GRADE_LVL_CD] = 'PK'
                                                     THEN -1
                                                     WHEN [MAX_GRADE_LVL_CD] = 'KN'
                                                     THEN 0
                                                     ELSE CAST([MAX_GRADE_LVL_CD] AS INT)
                                                END MAX_GRADE_LVL_CD
                                      FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll]
                                      WHERE     s.SchoolId = LOCATION_ID
                                    ) A
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
                                               ) B ON B.ID BETWEEN A.MAX_GRADE_LVL_CD
                                                           AND
                                                              A.[MAX_GRADE_LVL_CD]
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    SchoolCategory AS SchoolCategory ,
                                    SchoolType AS SchoolType
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        --( SELECT    AFCT.CodeValue AS 'AdministrativeFundingControl/CodeValue'
                        --  FROM      edfi.[AdministrativeFundingControlType] AFCT
                        --            INNER JOIN edfi.[AdministrativeFundingControlDescriptor] AFC ON AFCT.AdministrativeFundingControlTypeId = AFC.AdministrativeFundingControlTypeId
                        --  WHERE     S.[Ad`ministrativeFundingControlDescriptorId] = AFC.[AdministrativeFundingControlDescriptorId]
                        --FOR
                        --  XML PATH('') ,
                        --      TYPE
                        --) ,
                        ( SELECT    S.LocalEducationAgencyId AS 'LocalEducationAgencyReference/LocalEducationAgencyIdentity/LocalEducationAgencyId'
                        FOR
                          XML PATH('') ,
                              TYPE
                        )
              FROM      ( SELECT    a.*
                          FROM      ( SELECT    * ,
                                                ROW_NUMBER() OVER ( PARTITION BY SchoolId ORDER BY SCHOOL_YEAR DESC, SchoolId ) RowNumber
                                      FROM      ( SELECT DISTINCT
                                                            LOCATION_NAME NameOfInstitution ,
                                                            LOCATION_ID SchoolId ,
                                                            DISTRICT_CODE LocalEducationAgencyId ,
                                                            CASE LOCATION_STATUS
                                                              WHEN 'FUTURE'
                                                              THEN 'Future'
                                                              WHEN 'CLOSED'
                                                              THEN 'Closed'
                                                              WHEN 'CLOSEDGT1Y'
                                                              THEN 'Closed'
                                                              WHEN 'NEW'
                                                              THEN 'New'
                                                              WHEN 'RENUMBERED'
                                                              THEN 'Added'
                                                              WHEN 'CHANGED AGENCY'
                                                              THEN 'Changed Agency'
                                                              WHEN 'OPEN'
                                                              THEN 'Active'
                                                            END [OperationalStatus] ,
                                                            '5000005' StateOrganizationId ,
                                                            'School' EducationOrganizationCategory ,
                                                            CASE
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Non-Accredited%'
                                                              THEN 'All Levels'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Middle School'
                                                              THEN 'Middle School'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Special Education'
                                                              THEN 'All Levels'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Elementary School'
                                                              THEN 'Elementary School'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'High School'
                                                              THEN 'High School'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Central Office'
                                                              THEN 'Ungraded'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Prekindergarten'
                                                              THEN 'Primary School'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'State Supported'
                                                              THEN 'All Levels'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Junior High'
                                                              THEN 'Junior High School'
                                                              WHEN SCHOOL_TYPE_DESC LIKE 'Accredited private%'
                                                              THEN 'All Levels'
                                                              ELSE 'Other Combination'
                                                            END SchoolCategory ,
                                                            CASE ORG_TYPE_LONG
                                                              WHEN 'State Supported'
                                                              THEN 'Regular'
                                                              WHEN 'Private'
                                                              THEN 'Regular'
                                                              WHEN 'Central Office'
                                                              THEN 'Regular'
                                                              WHEN 'Charter'
                                                              THEN 'Regular'
                                                              WHEN 'Off-Site'
                                                              THEN 'Regular'
                                                              WHEN 'Public'
                                                              THEN 'Regular'
                                                            END SchoolType ,
                                                            SCHOOL_YEAR
                                                  FROM      staging.LOCATION_YEAR
                                                  WHERE     LOCATION_ID IN (
                                                            SELECT    DISTINCT
                                                              LOCATION_ID
                                                            FROM
                                                              staging.TEMPEdOrgCourses )
                                                ) aa
                                    ) a
                          WHERE     a.RowNumber = 1
                        ) S
            FOR
              XML PATH('School') ,
                  TYPE
            ) ,
            ( SELECT DISTINCT
                                            --( 'LOC_'
                                            --  + CASE WHEN ClassroomIdentificationCode = 'N/A' THEN '0' ELSE ClassroomIdentificationCode END ) AS "@id" ,
                        SchoolId AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        SchoolId ClassroomIdentificationCode ,
                        NULL MaximumNumberOfSeats ,
                        NULL OptimalNumberOfSeats
              FROM      ( SELECT    a.*
                          FROM      ( SELECT    * ,
                                                ROW_NUMBER() OVER ( ORDER BY SchoolId ) RowNumber
                                      FROM      ( SELECT DISTINCT
                                                            a.LOCATION_ID SchoolId
                                                  FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] a
                                                  WHERE     a.LOCATION_ID IN (
                                                            SELECT    DISTINCT
                                                              LOCATION_ID
                                                            FROM
                                                              staging.TEMPEdOrgCourses aa )
                                                ) aa
                                    ) a
                        ) a
											--where SchoolId = '1'
            FOR
              XML PATH('Location') ,
                  TYPE
            ) ,
            ( SELECT DISTINCT
                                            --( REPLACE('CPER_'
                                            --          + ClassPeriodName + '-'
                                            --          + CAST(SchoolId AS VARCHAR(9)),
                                            --          ' ', '') ) AS "@id" ,
                        SchoolId AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        1 ClassPeriodName
              FROM      ( SELECT    a.*
                          FROM      ( SELECT    * ,
                                                ROW_NUMBER() OVER ( ORDER BY SchoolId ) RowNumber
                                      FROM      ( SELECT DISTINCT
                                                            a.LOCATION_ID SchoolId
                                                  FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] a
                                                  WHERE     a.LOCATION_ID IN (
                                                            SELECT    DISTINCT
                                                              LOCATION_ID
                                                            FROM
                                                              staging.TEMPEdOrgCourses )
                                                ) aa
                                    ) a
                        ) a
											--where SchoolId = '1'
            FOR
              XML PATH('ClassPeriod') ,
                  TYPE
            ) ,
            ( SELECT    r.COURSE_ID AS CourseCode ,
                        ISNULL(LEFT(r.COURSE_NAME, 60), 'Uknown') CourseTitle ,
                        1 NumberOfParts ,
                        ( SELECT DISTINCT
                                    a3.CourseCode AS 'IdentificationCode' ,
                                    a3.CourseIdentificationSystem AS 'CourseIdentificationSystem/CodeValue' ,
                                    a3.CourseCode AS 'AssigningOrganizationIdentificationCode'
                          FROM      ( SELECT DISTINCT
                                                [LOCATION_ID] ,
                                                [COURSE_ID] [CourseCode] ,
                                                'LEA course code' CourseIdentificationSystem
      --,[STATE_COURSE_ID]
                                      FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] A1
                                      WHERE     A1.LOCATION_ID = r.LOCATION_ID
                                                AND A1.COURSE_ID = r.COURSE_ID
                                      UNION
                                      SELECT DISTINCT
                                                [LOCATION_ID] ,
                                                STATE_COURSE_ID [CourseCode] ,
                                                'State course code' CourseIdentificationSystem
                                      FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] A2
                                      WHERE     A2.LOCATION_ID = r.LOCATION_ID
                                                AND A2.LOCATION_ID = r.COURSE_ID
                                    ) a3
                        FOR
                          XML PATH('CourseIdentificationCode') ,
                              TYPE
                        ) ,
                        NULL AS CourseLevelCharacteristic ,
                        SUBJECT_AREA_DESC AS 'AcademicSubject/CodeValue' ,
                        'http://www.ped.state.nm.us/Descriptor/AcademicSubjectDescriptor.xml' AS 'AcademicSubject/Namespace' ,
                        NULL CourseDescription ,
                        NULL TimeRequiredForCompletion ,
                        NULL DateCourseAdopted ,
                        NULL HighSchoolCourseRequirement ,
                        NULL AS CourseGPAApplicability ,
                        NULL AS CourseDefinedBy ,
                        NULL AS 'MinimumAvailableCredits/Credits' ,
                        NULL AS 'MinimumAvailableCredits/CreditType' ,
                        NULL AS 'MinimumAvailableCredits/CreditConversion' ,
                        NULL AS 'MaximumAvailableCredits/Credits' ,
                        NULL AS 'MaximumAvailableCredits/MaximumAvailableCreditType' ,
                        NULL AS 'MaximumAvailableCredits/CreditConversion' ,
                        NULL AS CareerPathway ,
                        [LOCATION_ID] AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        NULL AS 'LearningStandardReference/LearningStandardIdentity/LearningStandardId'
              FROM      ( SELECT  DISTINCT
                                    LOCATION_ID ,
                                    COURSE_ID ,
                                    COURSE_NAME ,
                                    SUBJECT_AREA_DESC ,
                                    ROW_NUMBER() OVER ( PARTITION BY LOCATION_ID,
                                                        COURSE_ID ORDER BY SCHOOL_YEAR, COURSE_NAME ) RowId
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] C
                        ) r
              WHERE     r.LOCATION_ID IN ( SELECT   LOCATION_ID
                                           FROM     staging.TEMPEdOrgCourses )
                        AND RowId = 1
            FOR
              XML PATH('Course') ,
                  TYPE
            ) ,
            ( SELECT DISTINCT
                        b.LOCATION_ID AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        'Overall Letter Grade' RatingTitle ,
                        a.OverallLetter AS Rating ,
                        CAST(b.SCHOOL_YEAR - 1 AS NVARCHAR(4)) + '-'
                        + CAST(b.SCHOOL_YEAR AS NVARCHAR(4)) AS SchoolYear
              FROM      [staging].[SchoolGrades] a
                        INNER JOIN staging.LOCATION_YEAR b ON a.schnumb = b.[LOCATION_ID]
                                                              AND a.SchoolYear = b.SCHOOL_YEAR
              WHERE     a.OverallPts IS NOT NULL
            FOR
              XML PATH('AccountabilityRating') ,
                  TYPE
            ) ,

            --( SELECT    NULL AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            --            NULL ProgramId ,
            --            NULL ProgramName ,
            --            NULL AS ProgramType ,
            --            NULL AS 'ProgramCharacteristic/CodeValue' ,
            --            NULL AS ProgramSponsor ,
            --            NULL AS 'Service/CodeValue' ,
            --            NULL AS 'LearningObjectiveReference/LearningObjectiveIdentity/Objective' ,
            --            NULL AS 'LearningObjectiveReference/LearningObjectiveIdentity/AcademicSubject/CodeValue' ,
            --            NULL AS 'LearningObjectiveReference/LearningObjectiveIdentity/ObjectiveGradeLevel/CodeValue' ,
            --            NULL AS 'LearningStandardReference/LearningStandardIdentity/LearningStandardId'
            --  --FROM      ( SELECT    a.*
            --  --            FROM      ( SELECT    TSSAE.* ,
            --  --                                  ROW_NUMBER() OVER ( ORDER BY TSSAE.EducationOrganizationId ) RowNumber
            --  --                        FROM      edfi.Program TSSAE
            --  --                      ) a
            --  --            WHERE     RowNumber BETWEEN @startRow AND @endRow
            --  --          ) AS P
            --FOR
            --  XML PATH('Program') ,
            --      TYPE
            --) ,
            ( SELECT    CurrDate AS FactsAsOfDate ,
                        '2016-2017' AS SchoolYear ,
                        a.LOCATION_ID 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        ( SELECT DISTINCT
                                    FACT AS IndicatorFacts ,
                                    Criteria AS IndicatorCriteria ,
                                    CAST(PointsPossible AS NVARCHAR(7)) AS PointsPossible
                          FROM      staging.IndicatorInformation ii
                        FOR
                          XML PATH('IndicatorInformation') ,
                              TYPE
                        )
              FROM      ( SELECT DISTINCT
                                    CurrDate ,
                                    LOCATION_ID
                          FROM      staging.TEMPEdOrgCourses
                        ) a

			 

--join [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] b ON a.LOCATION_ID = b.LOCATION_ID
--JOIN staging.TeacherValuesAddedScores c ON c.ExternalStaffId = b.STAFF_ID
            FOR
              XML PATH('EducationOrganizationFacts') ,
                  TYPE
            ) ,
            ( SELECT    a.TeacherPreparationProviderId StateOrganizationId ,
                        NameOfInstitution ,
                        EducationOrganizationCategory ,
                        ( SELECT DISTINCT
                                    '300 Don Gaspar' StreetNumberName ,
                                    NULL ApartmentRoomSuiteNumber ,
                                    NULL BuildingSiteNumber ,
                                    'Santa Fe' City ,
                                    'NM' StateAbbreviation ,
                                    '87501' PostalCode ,
                                    NULL NameOfCounty ,
                                    NULL CountyFIPSCode ,
                                    NULL Latitude ,
                                    NULL Longitude ,
                                    NULL BeginDate ,
                                    NULL EndDate ,
                                    'Physical' AddressType
                        FOR
                          XML PATH('Address') ,
                              TYPE
                        ) ,
                        TeacherPreparationProviderId
              FROM      ( SELECT DISTINCT
                                    Institution_ID TeacherPreparationProviderId ,
                                    'NMEPP101' StateOrganizationId ,
                                    Institution_Name NameOfInstitution ,
                                    'Teacher Preparation Provider' EducationOrganizationCategory
                          FROM      staging.Completers aa
                          WHERE     Institution_ID IS NOT NULL
                                    AND [Program Type] IS NOT NULL
                          UNION
                          SELECT DISTINCT
                                    [Institution ID] ,
                                    'NMEPP101' StateOrganizationId ,
                                    InstitutionName ,
                                    'Teacher Preparation Provider' EducationOrganizationCategory
                          FROM      staging.Admissions ba
                          WHERE     [Institution ID] IS NOT NULL
                                    AND [Program Type] IS NOT NULL
                        ) a
            FOR
              XML PATH('TeacherPreparationProvider') ,
                  TYPE
            ) ,
            ( SELECT    R.TeacherPreparationProviderId AS 'EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        R.[Program Type] AS 'ProgramName' ,
                        'Other' AS 'ProgramType' ,
                        'Other' AS 'TPPProgramDegree/AcademicSubject/CodeValue' ,
                        'http://ed-fi.org/Descriptor/AcademicSubjectDescriptor.xml' AS 'TPPProgramDegree/AcademicSubject/Namespace' ,
                        'Other' AS 'TPPProgramDegree/TPPDegreeType/CodeValue' ,
                        'http://exchange.ed-fi.org/TPDP/Descriptor/TPPDegreeTypeDescriptor.xml' AS 'TPPProgramDegree/TPPDegreeType/Namespace'
              FROM      ( SELECT DISTINCT
                                    Institution_ID TeacherPreparationProviderId ,
                                    aa.[Program Type]
                          FROM      staging.Completers aa
                          WHERE     Institution_ID IS NOT NULL
                                    AND [Program Type] IS NOT NULL
                          UNION
                          SELECT DISTINCT
                                    [Institution ID] ,
                                    ba.[Program Type]
                          FROM      staging.Admissions ba
                          WHERE     [Institution ID] IS NOT NULL
                                    AND [Program Type] IS NOT NULL
                        ) R
            FOR
              XML PATH('TeacherPreparationProviderProgram') ,
                  TYPE
            )
    FOR     XML PATH('InterchangeEducationOrganization')
	--) xmldata
    --                  );

    --SET @result_new = REPLACE(CAST(@result AS VARCHAR(MAX)),
    --                          '<InterchangeEducationOrganization>',
    --                          '<InterchangeEducationOrganization xmlns="http://ed-fi.org/0200" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ed-fi.org/0200 D:\GitHub\Carlos\2.0Schemas\Interchange-EducationOrganization.xsd"> ');


    --SELECT  @result_new
    --FOR     XML PATH('');

    DROP TABLE staging.TEMPEdOrgCourses;


GO


