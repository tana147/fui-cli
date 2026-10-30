CREATE PROCEDURE [dbo].[spAPIFILE_UPLOAD_FileData] 
	@url1_SessionID varchar(36), 
	@sys_UserID varchar(9),  
	@sys_FileContent varbinary(max), 
	@sys_FileName nvarchar(200), 
	@sys_FileContentType varchar(100), 
	@sys_FileSize int
AS
BEGIN
	
	CREATE table #tblData (
		DataID varchar(36), 
		FileID char(36),
		FileName nvarchar(200),
		contentType varchar(100),
		FileSize int
	)
	insert into #tblData (DataID, FileID, FileName, contentType, FileSize)
	exec [eSignature_File].[dbo].[spIO_File_Upload] 
			@url1_SessionID, 
			@sys_FileContent, 
			@sys_FileName, 
			@sys_FileContentType, 
			@sys_FileSize

	select	FileID, dbo.fn_LoaiBoDau(@sys_FileName) FileName, @sys_FileSize FileSize
	from	#tblData

	drop table #tblData
END
