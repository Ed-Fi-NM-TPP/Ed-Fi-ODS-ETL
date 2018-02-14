
IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'PerformanceMeasure_Rubric_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[PerformanceMeasure_Rubric_proc]
    END
 GO


CREATE PROCEDURE [mapping].[PerformanceMeasure_Rubric_proc]
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
                            AND TABLE_NAME = 'TEMPRubric' ) )
        BEGIN
            DROP TABLE staging.TEMPRubric
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPRubric
    FROM    ( SELECT  DISTINCT
                        EducationOrganizationId ,
                        od.Assessment ,
                        DENSE_RANK() OVER ( ORDER BY EducationOrganizationId, Assessment ) RowNumber
              FROM      staging.ObservationDataPivot AS od
                        INNER JOIN staging.LOCATION_YEAR AS ly ON ly.LOCATION_ID = od.EducationOrganizationId
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;
    SELECT  EducationOrganizationId AS 'RubricEducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            'State' AS 'RubricType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/RubricTypeDescriptor.xml' AS 'RubricType/Namespace' ,
            Assessment AS RubricTitle
    FROM    staging.TEMPRubric
    FOR     XML PATH('Rubric') ,
                ROOT('InterchangePerformanceMeasure')
                                    
    DROP TABLE staging.TEMPRubric






GO


