
CREATE PROCEDURE [dbo].[spAPIFILE_FileData] @FileID char(36), @sys_UserID char(9)
AS
BEGIN
	
	exec [eSignature_File].[dbo].[spIO_File_Download] @FileID

END


