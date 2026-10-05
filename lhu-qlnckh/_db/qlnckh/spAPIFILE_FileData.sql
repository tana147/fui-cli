CREATE PROCEDURE [dbo].[spAPIFILE_FileData] @FileID CHAR(32)
AS
BEGIN

     SELECT 
           [FileName],
           ContentType,
           Size,
		   FileContent = BinaryContent
    FROM dbo.FileData
    WHERE FileID = @FileID
END