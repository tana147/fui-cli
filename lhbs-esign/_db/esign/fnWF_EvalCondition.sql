CREATE FUNCTION [dbo].[fnWF_EvalCondition]
(
    @fieldValue  NVARCHAR(500),
    @operator    VARCHAR(20),
    @condValue   NVARCHAR(500)
)
RETURNS BIT
AS
BEGIN
    IF @fieldValue IS NULL SET @fieldValue = ''
    IF @condValue  IS NULL SET @condValue  = ''

    -- String operators
    IF @operator = '=='       RETURN CASE WHEN @fieldValue =  @condValue  THEN 1 ELSE 0 END
    IF @operator = '!='       RETURN CASE WHEN @fieldValue <> @condValue  THEN 1 ELSE 0 END
    IF @operator = 'contains' RETURN CASE WHEN CHARINDEX(@condValue, @fieldValue) > 0 THEN 1 ELSE 0 END

    -- Numeric operators (return 0 if either value is not numeric)
    DECLARE @fNum FLOAT = TRY_CAST(@fieldValue AS FLOAT)
    DECLARE @cNum FLOAT = TRY_CAST(@condValue  AS FLOAT)
    IF @fNum IS NULL OR @cNum IS NULL RETURN 0

    IF @operator = '>'  RETURN CASE WHEN @fNum >  @cNum THEN 1 ELSE 0 END
    IF @operator = '<'  RETURN CASE WHEN @fNum <  @cNum THEN 1 ELSE 0 END
    IF @operator = '>=' RETURN CASE WHEN @fNum >= @cNum THEN 1 ELSE 0 END
    IF @operator = '<=' RETURN CASE WHEN @fNum <= @cNum THEN 1 ELSE 0 END

    RETURN 0
END
