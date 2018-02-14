
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'PerformanceMeasure_RubricLevelResponse_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[PerformanceMeasure_RubricLevelResponse_proc]
    END
 GO



CREATE PROCEDURE [mapping].[PerformanceMeasure_RubricLevelResponse_proc]
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
                            AND TABLE_NAME = 'TEMPRubricLevelResponse' ) )
        BEGIN
            DROP TABLE staging.TEMPRubricLevelResponse
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPRubricLevelResponse
    FROM    ( SELECT    * ,
                        ROW_NUMBER() OVER ( ORDER BY Id ) RowNumber
              FROM      ( SELECT   DISTINCT
                                    ObservationData.ObservationDataID ,
                                    ObservationData.Assessment ,
                                    ObservationData.Score ,
                                    ObservationData.ScoreName ,
                                    ObservationData.EducationOrganizationId ,
                                    Id
                          FROM      staging.ObservationDataPivot ObservationData
                                    INNER JOIN staging.LOCATION_YEAR AS ly ON ly.LOCATION_ID = ObservationData.EducationOrganizationId
                        ) R
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;

    SELECT  ObservationDataID AS 'PerformanceMeasureReference/PerformanceMeasureIdentity/PerformanceMeasureIdentifier' ,
            ( SELECT    EducationOrganizationId AS 'RubricReference/RubricIdentity/RubricEducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
                        'State' AS 'RubricReference/RubricIdentity/RubricType/CodeValue' ,
                        'http://exchange.ed-fi.org/TPDP/Descriptor/RubricTypeDescriptor.xml' AS 'RubricReference/RubricIdentity/RubricType/Namespace' ,
                        Assessment AS 'RubricReference/RubricIdentity/RubricTitle' ,
                        ScoreName AS 'RubricLevelCode'
              FROM      staging.ObservationDataPivot
              WHERE     ObservationData.Id = Id
                        AND ObservationData.EducationOrganizationId = EducationOrganizationId
            FOR
              XML PATH('RubricLevelIdentity') ,
                  TYPE
            ) AS 'RubricLevelReference' ,
            Score AS 'NumericResponse'
    FROM    staging.TEMPRubricLevelResponse ObservationData
    FOR     XML PATH('RubricLevelResponse') ,
                ROOT('InterchangePerformanceMeasure')
                                    
    DROP TABLE staging.TEMPRubricLevelResponse



--    SELECT  * ,
--            ROW_NUMBER() OVER ( ORDER BY Id ) RowNumber
--    FROM    ( SELECT   DISTINCT
--                        ObservationData.ObservationDataID ,
--                        ObservationData.Assessment ,
--                        ObservationData.Score ,
--                        ObservationData.ScoreName ,
--                        ObservationData.EducationOrganizationId
--              FROM      staging.ObservationDataPivot ObservationData
--                        INNER JOIN staging.LOCATION_YEAR AS ly ON ly.LOCATION_ID = ObservationData.SchoolID
--            ) R 
--GO




GO


