CREATE PROCEDURE spAPI_HDKH_DM_CRUD_ByTableName
		@ActionName VARCHAR(10),
		@TableName VARCHAR(50) ,
		@ParamsJSON NVARCHAR(MAX)
	AS 
		BEGIN

	DECLARE @ColumnTable TABLE (
		[Key] NVARCHAR(100),
		Value NVARCHAR(MAX)
	)
	-- Parse JSON
	INSERT INTO @ColumnTable ([Key], Value)
	SELECT [Key], Value
	FROM OPENJSON(@ParamsJSON)

	--Tạo SQL
	
	DECLARE @SQL NVARCHAR(MAX) = ''
	

	IF(@ActionName NOT IN ('INSERT','UPDATE','DELETE'))
	BEGIN
		  RAISERROR (N'Phương thức không tồn tại!', 16,1)
		  RETURN
	END
	-- Nếu action là insert thì tạo lệnh insert
	
	IF(@ActionName = 'INSERT')
	BEGIN
		DECLARE @Columns NVARCHAR(MAX) = ''
		DECLARE @Values NVARCHAR(MAX) = ''
		-- Nối cột
		SELECT @Columns = STUFF((
		SELECT ',' + QUOTENAME([Key])
		FROM @ColumnTable
		WHERE [Key] <> 'ID'
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

		-- Nối giá trị, nhớ thêm dấu nháy đơn cho chuỗi
		SELECT @Values = STUFF((
		SELECT ',' + QUOTENAME(Value, '''')
		FROM @ColumnTable
		WHERE [Key] <> 'ID'
		FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')


		-- Ghép thành câu SQL hoàn chỉnh
		SET @SQL = '
		    INSERT INTO ' +@TableName + '(' + @Columns + ')
		    VALUES (' + @Values + ')
		'
		
	END
	ELSE IF(@ActionName = 'UPDATE')
	BEGIN
		DECLARE @SetClause NVARCHAR(MAX)
		SELECT @SetClause = STUFF((
		SELECT ', ' + 
        QUOTENAME([Key]) + ' = ' +
        CASE 
            WHEN [Key] = 'ID' THEN Value  -- để nguyên số
			WHEN [Key] = 'IsActive' THEN Value
            ELSE QUOTENAME(Value, '''')  -- thêm dấu nháy cho chuỗi
        END
		FROM @ColumnTable
		WHERE [Key] <> 'ID'
		FOR XML PATH(''), TYPE
		).value('.', 'NVARCHAR(MAX)'), 1, 2, '')

		DECLARE @ID INT  
		SELECT @ID = CAST(Value AS INT) FROM @ColumnTable WHERE [Key] = 'ID'
		-- Ghép thành câu SQL hoàn chỉnh
		SET @SQL = '
		    UPDATE ' +@TableName + ' SET ' 
		    + @SetClause + ' WHERE ID = ' + CAST(@ID AS NVARCHAR) 
	END

	ELSE IF(@ActionName = 'DELETE')
	BEGIN
		DECLARE @ID_DELETE INT  
		SELECT @ID_DELETE = CAST(Value AS INT) FROM @ColumnTable WHERE [Key] = 'ID'
		-- Ghép thành câu SQL hoàn chỉnh
		SET @SQL = '
		    UPDATE ' +@TableName + ' SET IsActive = 0 WHERE ID = ' + CAST(@ID_DELETE AS NVARCHAR) 
	END

	BEGIN TRY
    EXEC sp_executesql @SQL
END TRY
BEGIN CATCH
    DECLARE @ErrorMessage NVARCHAR(4000)
    DECLARE @ErrorSeverity INT
    DECLARE @ErrorState INT

    SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE()
    -- Có thể bỏ nếu chỉ muốn in lỗi mà không báo lên
    RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState)
END CATCH
END