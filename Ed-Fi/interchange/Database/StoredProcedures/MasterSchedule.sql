
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'MasterSchedule_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[MasterSchedule_proc]
    END
 GO






CREATE PROCEDURE [mapping].[MasterSchedule_proc]
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
                            AND TABLE_NAME = 'TEMPMasterScheduleSection' ) )
        BEGIN
            DROP TABLE staging.TEMPMasterScheduleSection
        END

    SELECT  a.*
    INTO    staging.TEMPMasterScheduleSection
    FROM    ( SELECT    [LOCATION_ID] ,
                        [CourseCode] ,
                        SequenceOfCourse ,
                        ClassPeriodName ,
                        SECTION_CODE ,
                        Term ,
                        SchoolYearDescription ,
                        SCHOOL_YEAR ,
                        DENSE_RANK() OVER ( ORDER  BY [LOCATION_ID], [CourseCode], SECTION_CODE ) RowNumber
              FROM      ( SELECT DISTINCT
                                    a.[LOCATION_ID] ,
                                    [COURSE_ID] [CourseCode] ,
                                    1 SequenceOfCourse ,
                                    1 ClassPeriodName ,
                                    SECTION_CODE ,
                                    'Other' Term ,
                                    CAST(a.SCHOOL_YEAR - 1 AS NVARCHAR(4))
                                    + '-' + CAST(a.SCHOOL_YEAR AS NVARCHAR(4)) SchoolYearDescription ,
                                    a.SCHOOL_YEAR
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] a
                                    JOIN staging.LOCATION_YEAR LY ON a.LOCATION_KEY = LY.LOCATION_KEY
                                                              AND a.SCHOOL_YEAR = LY.SCHOOL_YEAR
                        ) vci
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
	--DECLARE @FileName NVARCHAR(1000) = 'MasterSchedule-2.0'+'_'+CAST(@iteration AS NVARCHAR(3));

    --SELECT  @result = ( 
	--INSERT INTO mapping.XMLData
	--SELECT @FileName,(
    SELECT  ( SELECT DISTINCT
                        C.[CourseCode] LocalCourseCode ,
                        C.[CourseTitle] LocalCourseTitle ,
                        NULL InstructionalTimePlanned ,
                        C.[LOCATION_ID] AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        C.[LOCATION_ID] AS 'SessionReference/SessionIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
                        CAST(C.SCHOOL_YEAR - 1 AS NVARCHAR(4)) + '-'
                        + CAST(C.SCHOOL_YEAR AS NVARCHAR(4)) AS 'SessionReference/SessionIdentity/SchoolYear' ,
                        'Other' AS 'SessionReference/SessionIdentity/Term/CodeValue' ,
                        C.[CourseCode] AS 'CourseReference/CourseIdentity/CourseCode' ,
                        C.[LOCATION_ID] AS 'CourseReference/CourseIdentity/EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId'
              FROM      ( SELECT    [LOCATION_ID] ,
                                    [CourseCode] ,
                                    [CourseTitle] ,
                                    SCHOOL_YEAR ,
                                    ROW_NUMBER() OVER ( PARTITION  BY LOCATION_ID,
                                                        CourseCode,
                                                        SCHOOL_YEAR ORDER BY CourseTitle ) RowNumber
                          FROM      ( SELECT DISTINCT
                                                A.[LOCATION_ID] ,
                                                [COURSE_ID] [CourseCode] ,
                                                A.SCHOOL_YEAR ,
                                                CAST(ISNULL([COURSE_NAME],
                                                            'Uknown') AS NVARCHAR(60)) [CourseTitle]
                                      FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] A
                                                JOIN staging.TEMPMasterScheduleSection b ON b.CourseCode = A.COURSE_ID
                                                              AND A.LOCATION_ID = b.LOCATION_ID
                                                              AND A.SECTION_CODE = b.SECTION_CODE
                                                              AND A.SCHOOL_YEAR = b.SCHOOL_YEAR
                                    ) vci
                        ) AS C
              WHERE     C.RowNumber = 1
            FOR
              XML PATH('CourseOffering') ,
                  TYPE
            ) ,
            ( SELECT    ( SELECT  DISTINCT
                                    S.SECTION_CODE UniqueSectionCode ,
                                    S.SequenceOfCourse ,
                                    NULL AS EducationalEnvironment ,
                                    NULL AS MediumOfInstruction ,
                                    NULL AS PopulationServed
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    NULL AS 'AvailableCredits/Credits' ,
                                    NULL AS 'AvailableCredits/CreditType' ,
                                    NULL AS 'AvailableCredits/CreditConversion'
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT    NULL AS 'InstructionalLanguage/CodeValue'
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT  DISTINCT
                                    S.CourseCode LocalCourseCode ,
                                    S.[LOCATION_ID] AS 'SessionReference/SessionIdentity/SchoolReference/SchoolIdentity/SchoolId' ,
                                    S.schoolyeardescription AS 'SessionReference/SessionIdentity/SchoolYear' ,
                                    S.Term AS 'SessionReference/SessionIdentity/Term/CodeValue' ,
                                    S.[LOCATION_ID] AS 'SchoolReference/SchoolIdentity/SchoolId'
                        FOR
                          XML PATH('CourseOfferingIdentity') ,
                              ROOT('CourseOfferingReference') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    S.[LOCATION_ID] AS 'SchoolReference/SchoolIdentity/SchoolId'
                        FOR
                          XML PATH('') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    S.[LOCATION_ID] AS 'LocationIdentity/ClassroomIdentificationCode' ,
                                    S.[LOCATION_ID] AS 'LocationIdentity/SchoolReference/SchoolIdentity/SchoolId'
                        FOR
                          XML PATH('LocationReference') ,
                              TYPE
                        ) ,
                        ( SELECT DISTINCT
                                    S.ClassPeriodName 'ClassPeriodIdentity/ClassPeriodName' ,
                                    S.[LOCATION_ID] AS 'ClassPeriodIdentity/SchoolReference/SchoolIdentity/SchoolId'
                        FOR
                          XML PATH('ClassPeriodReference') ,
                              TYPE
                        ) --+,
                        --( SELECT DISTINCT
                        --            NULL AS 'ProgramIdentity/ProgramType' ,
                        --            NULL 'ProgramIdentity/ProgramName' ,
                        --            NULL AS 'ProgramIdentity/EducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId'
                        --FOR
                        --  XML PATH('ProgramReference') ,
                        --      TYPE
                        --)
              FROM      staging.TEMPMasterScheduleSection AS S
              WHERE     S.CourseCode IS NOT NULL
                        AND S.LOCATION_ID IS NOT NULL
                        AND S.Term IS NOT NULL
                        AND S.SchoolYearDescription IS NOT NULL
            FOR
              XML PATH('Section') ,
                  TYPE
            ) --,
            --( SELECT    ( SELECT    NULL BellScheduleName ,
            --                        NULL AS 'GradeLevel/CodeValue' ,
            --                        NULL 'SchoolReference/SchoolIdentity/SchoolId'
            --            FOR
            --              XML PATH('') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    ( SELECT DISTINCT
            --                                    NULL 'ClassPeriodIdentity/ClassPeriodName' ,
            --                                    NULL AS 'ClassPeriodIdentity/SchoolReference/SchoolIdentity/SchoolId'
            --                        FOR
            --                          XML PATH('ClassPeriodReference') ,
            --                              TYPE
            --                        ) ,
            --                        NULL AlternateDayName ,
            --                        NULL StartTime ,
            --                        NULL EndTime ,
            --                        NULL OfficialAttendancePeriod
            --            FOR
            --              XML PATH('MeetingTime') ,
            --                  TYPE
            --            ) ,
            --            ( SELECT    NULL AS 'CalendarDateIdentity/Date' ,
            --                        NULL AS 'CalendarDateIdentity/SchoolReference/SchoolIdentity/SchoolId'
            --            FOR
            --              XML PATH('CalendarDateReference') ,
            --                  TYPE
            --            )
              
            --FOR
            --  XML PATH('BellSchedule') ,
            --      TYPE
            --)
    FOR     XML PATH('InterchangeMasterSchedule')
	--) xmldata
    --                  );



    --SET @result_new = REPLACE(CAST(@result AS VARCHAR(MAX)),
    --                          '<InterchangeMasterSchedule>',
    --                          '<InterchangeMasterSchedule xmlns="http://ed-fi.org/0200" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ed-fi.org/0200 D:\GitHub\Carlos\2.0Schemas\Interchange-MasterSchedule.xsd"> ');


    --SELECT  @result_new
    --FOR     XML PATH('');

    DROP TABLE staging.TEMPMasterScheduleSection;















GO


