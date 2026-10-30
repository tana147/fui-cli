CREATE PROCEDURE [dbo].[CallFormulaString]
    @formular NVARCHAR(MAX),
    @Result FLOAT OUTPUT 
AS
BEGIN
     DECLARE @SQL nvarchar(max);

    SET @SQL = 'SELECT @Result = round(' + @formular+',2)';
	--set @ResultFormular = @SQL;
    EXEC sp_executesql @SQL, N'@Result FLOAT OUTPUT', @Result OUTPUT
END
