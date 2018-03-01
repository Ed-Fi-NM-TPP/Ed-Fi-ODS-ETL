

IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   object_id = OBJECT_ID(N'[dbo].[erf]')
                    AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ) )
    DROP FUNCTION [dbo].[erf]
GO

/****** Object:  UserDefinedFunction [dbo].[erf]    Script Date: 3/1/2018 8:10:55 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[erf] ( @x FLOAT )
RETURNS FLOAT
    BEGIN

        DECLARE @p FLOAT= 0.3275911;
        DECLARE @a1 FLOAT = 0.254829592
        DECLARE @a2 FLOAT = -0.284496736
        DECLARE @a3 FLOAT = 1.421413741
        DECLARE @a4 FLOAT = -1.453152027
        DECLARE @a5 FLOAT= 1.061405429

        DECLARE @t FLOAT= 1.0 / ( 1.0 + @p * ABS(@x) );

        DECLARE @erfx FLOAT = 1 - ( @a1 * @t + @a2 * POWER(@t, 2) + @a3
                                    * POWER(@t, 3) + @a4 * POWER(@t, 4) + @a5
                                    * POWER(@t, 5) ) * EXP(-SQUARE(@x))
        IF ( @x < 0 )
            BEGIN
                SET @erfx = -@erfx

            END

        RETURN @erfx
    END 

GO


