CREATE PROC [dbo].[spAPIFILE_UPLOAD_FileAdapter]
    @sys_UserID VARCHAR(9),
    @sys_FileContent VARBINARY(MAX),
    @sys_FileName NVARCHAR(200),
    @sys_FileContentType VARCHAR(100),
    @sys_FileSize INT
AS
BEGIN
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

    --SELECT FILE_ID = @FileID,
    --       [FILE_NAME] = @sys_FileName,
    --       FILE_CONTENTTYPE = @sys_FileContentType,
    --       FILE_SIZE = @sys_FileSize,
    --       FILE_URL = '/FileData/' + @FileID

	SELECT json_data = '{"url":"'+ 'https://file.lhbs.vn/lms/FileData/' + @FileID +'.jpg"}'

END
