
IF NOT EXISTS (
SELECT  schema_name
FROM    information_schema.schemata
WHERE   schema_name = 'mapping' ) 

BEGIN
EXEC sp_executesql N'CREATE SCHEMA mapping authorization dbo'
END

IF NOT EXISTS (
SELECT  schema_name
FROM    information_schema.schemata
WHERE   schema_name = 'staging' ) 

BEGIN
EXEC sp_executesql N'CREATE SCHEMA staging authorization dbo'
END
