CREATE PROC [dbo].[spAPIFILE_UPLOAD_LMS_FileData_Update]
	@FileID CHAR(32),
    @sys_UserID VARCHAR(9),
    @sys_FileContent VARBINARY(MAX),
    @sys_FileName NVARCHAR(200),
    @sys_FileContentType VARCHAR(100),
    @sys_FileSize INT
AS
BEGIN
	
	EXEC [LMS-LHBS-file].[dbo].[spIO_IN_FileUpdate] 
	@FileID = @FileID
	, @FileData = @sys_FileContent
	, @FileName = @sys_FileName
	, @CreateUser = @sys_UserID


END
