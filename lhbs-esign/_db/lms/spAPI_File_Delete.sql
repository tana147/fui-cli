
Create proc spAPI_File_Delete
@FileID VARCHAR(32)
AS
BEGIN
	DELETE
    FROM dbo.FileData
    WHERE FileID = @FileID
END