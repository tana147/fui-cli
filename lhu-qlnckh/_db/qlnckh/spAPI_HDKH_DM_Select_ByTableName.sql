CREATE PROCEDURE spAPI_HDKH_DM_Select_ByTableName
	@TableName varchar(100)
	AS
	BEGIN
		DECLARE @SQL NVARCHAR(MAX)
		SET @SQL = N'SELECT * FROM ' + QUOTENAME(@TableName) + ' WHERE IsActive = 1'
		EXEC sp_executesql @SQL 
	END