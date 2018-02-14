

IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'EducationOrgCalendar_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[EducationOrgCalendar_proc]
    END
 GO





CREATE PROCEDURE [mapping].[EducationOrgCalendar_proc]
    (
      @iteration INT = 0 ,
      @maxRecords INT = 300000
    )
AS
    DECLARE @result XML;

    DECLARE @result_new XML;

    DECLARE @startRow INT = ( @maxRecords * @iteration ) + 1

    DECLARE @endRow INT = ( @maxRecords * @iteration ) + @maxRecords

    --DECLARE @FileName NVARCHAR(1000) = 'EducationOrgCalendar-2.0'+'_'+CAST(@iteration AS NVARCHAR(3));

    --SELECT  @result = ( 
	--INSERT INTO mapping.XMLData
	--SELECT @FileName,(
    IF ( EXISTS ( SELECT    *
                  FROM      INFORMATION_SCHEMA.TABLES
                  WHERE     TABLE_SCHEMA = 'staging'
                            AND TABLE_NAME = 'TEMPEdOrgCalendar' ) )
        BEGIN
            DROP TABLE staging.TEMPEdOrgCalendar
        END

    SELECT  a.*
    INTO    staging.TEMPEdOrgCalendar
    FROM    ( SELECT    [LOCATION_ID] ,
                        SessionName ,
                        BeginDate ,
                        EndDate ,
                        TotalInstructionalDays ,
                        Term ,
                        SchoolYearDescription ,
                        GradingPeriod ,
                        ROW_NUMBER() OVER ( ORDER BY vci.[LOCATION_ID] ) RowNumber
              FROM      ( SELECT DISTINCT
                                    CAST(a.SCHOOL_YEAR AS NVARCHAR(4)) SessionName ,
                                    a.[LOCATION_ID] ,
                                    'Other' Term ,
                                    CAST(a.SCHOOL_YEAR - 1 AS NVARCHAR(4))
                                    + '-' + CAST(a.SCHOOL_YEAR AS NVARCHAR(4)) SchoolYearDescription ,
                                    '08-01-'
                                    + CAST(a.SCHOOL_YEAR - 1 AS NVARCHAR(4)) BeginDate ,
                                    '07-31-'
                                    + CAST(a.SCHOOL_YEAR AS NVARCHAR(4)) EndDate ,
                                    180 TotalInstructionalDays ,
                                    'End of Year' GradingPeriod
                          FROM      [staging].[vw_crse_instruct_snapshot_staff_snapshot_course_state_enroll] a
                                    JOIN staging.LOCATION_YEAR LY ON a.LOCATION_KEY = LY.LOCATION_KEY
                                                              AND a.SCHOOL_YEAR = LY.SCHOOL_YEAR
                        ) vci
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;


    SELECT  ( SELECT    SessionName ,
                        SchoolYearDescription AS SchoolYear ,
                        Term AS 'Term/CodeValue' ,
                        BeginDate ,
                        EndDate ,
                        TotalInstructionalDays ,
                        [LOCATION_ID] AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        ( SELECT DISTINCT
                                    'Id_'
                                    + CAST([LOCATION_ID] AS NVARCHAR(10))
                                    + CAST(GradingPeriod AS NVARCHAR(20))
                                    + CAST(BeginDate AS NVARCHAR(10)) AS '@ref'
                        FOR
                          XML PATH('GradingPeriodReference') ,
                              TYPE
                        )
              FROM      staging.TEMPEdOrgCalendar
            FOR
              XML PATH('Session') ,
                  TYPE
            ) ,
            ( SELECT  DISTINCT
                        'Id_' + CAST([LOCATION_ID] AS NVARCHAR(10))
                        + CAST(GradingPeriod AS NVARCHAR(20))
                        + CAST(BeginDate AS NVARCHAR(10)) AS '@id' ,
                        [LOCATION_ID] AS 'SchoolReference/SchoolIdentity/SchoolId' ,
                        GradingPeriod AS 'GradingPeriod/CodeValue' ,
                        BeginDate ,
                        EndDate ,
                        [TotalInstructionalDays] ,
                        1 PeriodSequence
              FROM      staging.TEMPEdOrgCalendar
            FOR
              XML PATH('GradingPeriod') ,
                  TYPE
            ) --,
            --( SELECT  DISTINCT
            --            CD.Date ,
            --            CD.EducationOrganizationId AS 'SchoolReference/SchoolIdentity/SchoolId' ,
            --            1 AS 'CalendarEvent/EventDuration' ,
            --            CET.CodeValue AS 'CalendarEvent/CalendarEvent/CodeValue'
            --  FROM      ( SELECT    a.*
            --              FROM      ( SELECT    TSSAE.* ,
            --                                    ROW_NUMBER() OVER ( ORDER BY TSSAE.EducationOrganizationId ) RowNumber
            --                          FROM      edfi.CalendarDate TSSAE
            --                        ) a
            --              WHERE     RowNumber BETWEEN @startRow AND @endRow
            --            ) CD
            --            INNER JOIN edfi.CalendarEventType CET ON CD.CalendarEventTypeId = CET.CalendarEventTypeId
            --FOR
            --  XML PATH('CalendarDate') ,
            --      TYPE
            --) ,
            --( SELECT  DISTINCT
            --            A.SchoolId AS 'SchoolReference/SchoolIdentity/SchoolId' ,
            --            A.WeekIdentifer WeekIdentifier ,
            --            A.BeginDate ,
            --            A.EndDate ,
            --            A.TotalInstructionalDays
            --  FROM      ( SELECT    a.*
            --              FROM      ( SELECT    TSSAE.* ,
            --                                    ROW_NUMBER() OVER ( ORDER BY TSSAE.SchoolId ) RowNumber
            --                          FROM      edfi.AcademicWeek TSSAE
            --                        ) a
            --              WHERE     RowNumber BETWEEN @startRow AND @endRow
            --            ) A
            --FOR
            --  XML PATH('AcademicWeek') ,
            --      TYPE
            --)
    FOR     XML PATH('InterchangeEducationOrgCalendar')
	--) xmldata
    --                  );


    --SET @result_new = REPLACE(CAST(@result AS VARCHAR(MAX)),
    --                          '<InterchangeEducationOrgCalendar>',
    --                          '<InterchangeEducationOrgCalendar xmlns="http://ed-fi.org/0200" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ed-fi.org/0200 D:\GitHub\Carlos\2.0Schemas\Interchange-EducationOrgCalendar.xsd"> ');
    DROP TABLE staging.TEMPEdOrgCalendar

    --SELECT  @result_new
    --FOR     XML PATH('');







GO


