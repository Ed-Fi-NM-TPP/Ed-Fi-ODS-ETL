IF EXISTS ( SELECT  1
            FROM    master.dbo.syslogins
            WHERE   loginname = 'metricsuser'
            UNION
            SELECT  1
            FROM    sysusers
            WHERE   name = 'metricsuser' )
    BEGIN
        IF NOT EXISTS ( SELECT  name
                        FROM    sys.database_principals
                        WHERE   name = 'metricsuser' )
            BEGIN
                CREATE USER [metricsuser] FOR LOGIN [metricsuser] WITH DEFAULT_SCHEMA=[edfi]
            END
        EXEC sp_addrolemember N'db_datawriter', N'metricsuser'
        EXEC sp_addrolemember N'db_datareader', N'metricsuser'
        GRANT EXECUTE TO [metricsuser]
    END
GO