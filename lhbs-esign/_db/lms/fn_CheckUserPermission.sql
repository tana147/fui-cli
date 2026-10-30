CREATE   FUNCTION dbo.fn_CheckUserPermission
(
    @SystemRight int,
    @FunctionRight varchar(2000),
    @AllowedSystemRights varchar(100),
    @RequiredFunctionCode int
)
RETURNS bit
AS
BEGIN
    DECLARE @Result bit = 0;
    DECLARE @SystemRightToken varchar(20);
    DECLARE @FunctionRightToken varchar(20);

    IF ISNULL(@SystemRight, 0) = 9
        RETURN 1;

    SET @SystemRightToken = '[' + CONVERT(varchar(10), @SystemRight) + ']';

    IF CHARINDEX(@SystemRightToken, ISNULL(@AllowedSystemRights, '')) = 0
        RETURN 0;

    IF @RequiredFunctionCode IS NULL
        RETURN 1;

    SET @FunctionRightToken = '[' + CONVERT(varchar(10), @RequiredFunctionCode) + ']';

    IF CHARINDEX(@FunctionRightToken, ISNULL(@FunctionRight, '')) > 0
        SET @Result = 1;

    RETURN @Result;
END