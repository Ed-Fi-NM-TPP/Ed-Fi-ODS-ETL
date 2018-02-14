

IF EXISTS ( SELECT  *
            FROM    sysobjects
            WHERE   type = 'P'
                    AND name = 'PerformanceMeasure_RubricLevel_proc' )
    BEGIN
        DROP  PROCEDURE [mapping].[PerformanceMeasure_RubricLevel_proc]
    END
 GO



CREATE PROCEDURE [mapping].[PerformanceMeasure_RubricLevel_proc]
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
                            AND TABLE_NAME = 'TEMPRubricLevel' ) )
        BEGIN
            DROP TABLE staging.TEMPRubricLevel
        END

    SELECT  a.* ,
            CAST(GETDATE() AS DATE) CurrDate
    INTO    staging.TEMPRubricLevel
    FROM    ( SELECT  DISTINCT
                        EducationOrganizationId ,
                        ScoreName ,
                        od.Assessment ,
                        DENSE_RANK() OVER ( ORDER BY od.EducationOrganizationId, Assessment, ScoreName ) RowNumber
              FROM      staging.ObservationDataPivot AS od
                        LEFT JOIN staging.TeacherEvaluationsV3 AS te ON te.SchoolID = od.SchoolID
                                                              AND te.YearEnding = od.YearEnding
                                                              AND od.LicenseNumber = te.LicenseNumber
                        INNER JOIN staging.LOCATION_YEAR AS ly ON ly.LOCATION_ID = od.EducationOrganizationId
            ) a
    WHERE   RowNumber BETWEEN @startRow AND @endRow;

    SELECT  EducationOrganizationId AS 'RubricReference/RubricIdentity/RubricEducationOrganizationReference/EducationOrganizationIdentity/EducationOrganizationId' ,
            'State' AS 'RubricReference/RubricIdentity/RubricType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/RubricTypeDescriptor.xml' AS 'RubricReference/RubricIdentity/RubricType/Namespace' ,
            Assessment AS 'RubricReference/RubricIdentity/RubricTitle' ,
            ScoreName AS 'RubricLevelCode' ,
            CASE WHEN ScoreName LIKE '%1%' THEN 1
                 WHEN scoreName LIKE '%2%' THEN 2
                 WHEN scoreName LIKE '%3%' THEN 3
                 ELSE 4
            END AS 'RubricLevelInformation/LevelType/CodeValue' ,
            'http://exchange.ed-fi.org/TPDP/Descriptor/LevelTypeDescriptor.xml' AS 'RubricLevelInformation/LevelType/Namespace' ,
            CASE WHEN scoreName = 'D1A'
                 THEN 'Demonstrating Knowledge of Content'
                 WHEN scoreName = 'D1B' THEN 'Designing Coherent Instruction'
                 WHEN scoreName = 'D1C' THEN 'Setting Instructional Outcomes'
                 WHEN scoreName = 'D1D'
                 THEN 'Demonstrating Knowledge of Resources'
                 WHEN scoreName = 'D1E'
                 THEN ' Demonstrating Knowledge of Students'
                 WHEN scoreName = 'D1F' THEN 'Designing Student Assessment'
                 WHEN scoreName = 'D2A'
                 THEN 'Creating an Environment of Respect and Rapport'
                 WHEN scoreName = 'D2B' THEN 'Organizing Physical Space-'
                 WHEN scoreName = 'D2C'
                 THEN 'Establishing a Culture for Learning'
                 WHEN scoreName = 'D2D' THEN 'Managing Classroom Procedure'
                 WHEN scoreName = 'D2E' THEN 'Managing Student Behavior'
                 WHEN scoreName = 'D3A'
                 THEN 'Communicating with Students in a Manner that is Appropriate to their Culture and Level of Development'
                 WHEN scoreName = 'D3B'
                 THEN 'Using Questioning and Discussion Techniques to Support Classroom Discourse'
                 WHEN scoreName = 'D3C' THEN 'Engaging Students in Learning'
                 WHEN scoreName = 'D3D' THEN 'Assessment in Instruction'
                 WHEN scoreName = 'D3E'
                 THEN 'Demonstrating Flexibility and Responsiveness'
                 WHEN scoreName = 'D4A'
                 THEN 'Demonstrating Knowledge of Content'
                 WHEN scoreName = 'D4B' THEN 'Designing Coherent Instruction'
                 WHEN scoreName = 'D4C' THEN 'Setting Instructional Outcomes'
                 WHEN scoreName = 'D4D'
                 THEN 'Demonstrating Knowledge of Resources'
                 WHEN scoreName = 'D4E'
                 THEN 'Demonstrating Knowledge of Students'
                 WHEN scoreName = 'D4F' THEN 'Designing Student Assessment'
            END AS 'RubricLevelInformation/LevelTitle'
    FROM    staging.TEMPRubricLevel
    FOR     XML PATH('RubricLevel') ,
                ROOT('InterchangePerformanceMeasure')
                                    
    DROP TABLE staging.TEMPRubricLevel





GO


