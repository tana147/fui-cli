
CREATE PROCEDURE [dbo].[spAPIFILE_UPLOAD_ImageAdapter] 
	@sys_UserID VARCHAR(9), 
	@url1_maxWidth INT, 
	@url2_maxHeight INT, 
	@url3_Qua INT, 
	@sys_FunctionRight VARCHAR(100), 
	@sys_FileContent VARBINARY(MAX), 
	@sys_FileName NVARCHAR(100), 
	@sys_FileContentType VARCHAR(100), 
	@sys_FileSize INT, 
	@sys_UploadData NVARCHAR(1000)
AS
BEGIN
	IF (@url1_maxWidth IS NULL OR @url2_maxHeight IS NULL OR @url3_Qua IS NULL)
	BEGIN
		RAISERROR(N'Thiết lập thông số API chưa đúng', 16, 1)
		RETURN 0;
	END
	BEGIN TRY  
		SET @sys_FileContent = [dbo].[FN_IMAGE_RESIZE]('.jpg', @sys_FileContent , @url1_maxWidth, @url2_maxHeight, 1, @url3_Qua)
	END TRY  
	BEGIN CATCH  
		RAISERROR(N'Hình không resize được', 16, 1)
		RETURN 0;
	END CATCH 
	
	DECLARE @FileID VARCHAR(36) = REPLACE(NEWID(), '-', '')

    INSERT INTO dbo.FileData
    (
        FileID,
        [FileName],
        BinaryContent,
        ContentType,
        Size,
        CreateUser
    )
    VALUES
    (
        @FileID,
        @sys_FileName,
        @sys_FileContent,
        @sys_FileContentType,
        @sys_FileSize,
        @sys_UserID
    )

	SELECT json_data = '{"url":"'+ 'https://file.zentea.vn/eorder/auth/FileData/' + @FileID +'.jpg"}'
END
