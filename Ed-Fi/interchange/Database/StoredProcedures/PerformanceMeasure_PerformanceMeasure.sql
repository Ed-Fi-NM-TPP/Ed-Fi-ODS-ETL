
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'PerformanceMeasure_PerformanceMeasure_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[PerformanceMeasure_PerformanceMeasure_proc]
    END
 GO





CREATE PROCEDURE [mapping].[PerformanceMeasure_PerformanceMeasure_proc]
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
                            AND TABLE_NAME = 'TEMPPerformanceMeasure' ) )
        BEGIN
            DROP TABLE staging.TEMPPerformanceMeasure
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPPerformanceMeasure
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY Temp.ObservationDataID ) RowNumber
              FROM      ( SELECT    DISTINCT
                                    te.StudentAchievement1Points ,
                                    te.StudentAchievement1PossiblePoints ,
                                    od.YearEnding ,
                                    ObservationDataID ,
                                    od.Assessment ,
                                    EducationOrganizationId ,
                                    RIGHT(staff.STAFF_ID, 5)
                                    + REPLACE(CONVERT(NVARCHAR(10), CAST(staff.STAFF_BIRTHDATE AS DATETIME), 111),
                                              '/', '') AS StaffUniqueId ,
                                    t.FirstName ,
                                    t.LastName
                          FROM      staging.ObservationDataPivot AS od
                                    INNER JOIN staging.LOCATION_YEAR AS ly ON ly.LOCATION_ID = od.EducationOrganizationId
                                    LEFT JOIN staging.TeacherEvaluationsV3 AS te ON te.SchoolID = od.SchoolID
                                                              AND te.YearEnding = od.YearEnding
                                                              AND od.LicenseNumber = te.LicenseNumber
                                                              AND od.DistrictCode = te.DistrictCode
                                    LEFT JOIN staging.Teachers AS t ON t.LicenseNumber = od.LicenseNumber
                                                              AND t.SchoolYear = od.YearEnding
                                                              AND t.TeacherID = te.TeacherID
                                    LEFT JOIN ( SELECT DISTINCT
                                                        a.STAFF_ID ,
                                                        a.STAFF_BIRTHDATE, ROW_NUMBER() over ( partition by a.Staff_ID  order by SNAPSHOT_DATE) RecentBirthday
                                                FROM    staging.STAFF a
                                                        INNER JOIN staging.STAFF_SNAPSHOT
                                                        AS ss ON ss.STAFF_KEY = a.STAFF_KEY
                                              ) staff ON staff.STAFF_ID = t.ExternalStaffID AND RecentBirthday = 1
                        ) Temp
              WHERE     Temp.StaffUniqueId IS NOT NULL
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;


    SELECT  ObservationDataID AS PerformanceMeasureIdentifier ,
            'Performance Evaluation' AS 'PerformanceMeasureType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/PerformanceMeasureTypeDescriptor.xml' AS 'PerformanceMeasureType/Namespace' ,
            EducationOrganizationid AS 'RubricReference/RubricIdentity/RubricEducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            'State' AS 'RubricReference/RubricIdentity/RubricType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/RubricTypeDescriptor.xml' AS 'RubricReference/RubricIdentity/RubricType/Namespace' ,
            Assessment AS 'RubricReference/RubricIdentity/RubricTitle' ,
            'Other' AS 'Term/CodeValue' ,
            'http://ed-fi.org/Descriptor/TermDescriptor.xml' AS 'Term/Namespace' ,
            ( SELECT DISTINCT
                        FirstName 'FirstName' ,
                        LastName 'LastSurname' ,
                        StaffUniqueId AS 'PersonBeingReviewedStaffReference/StaffIdentity/StaffUniqueId'
              FROM      staging.TEMPPerformanceMeasure B
              WHERE     A.RowNumber = B.RowNumber
                        AND ( A.FirstName IS NOT NULL
                              AND A.LastName IS NOT NULL
                            )
            FOR
              XML PATH('PersonBeingReviewed') ,
                  TYPE
            ) ,
            CONVERT(CHAR(10), CONVERT(DATETIME, YearEnding), 126) AS 'ActualDateOfPerformanceMeasure' ,
            CAST(YEAR(YearEnding) AS NVARCHAR(4)) AS 'ObservationEndYear'
    FROM    staging.TEMPPerformanceMeasure A
    FOR     XML PATH('PerformanceMeasure') ,
                ROOT('InterchangePerformanceMeasure')
                                    
    DROP TABLE staging.TEMPPerformanceMeasure


















GO


