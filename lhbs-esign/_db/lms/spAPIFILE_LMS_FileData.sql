CREATE PROCEDURE [dbo].[spAPIFILE_LMS_FileData] @FileID CHAR(32)
AS
BEGIN

	EXEC [LMS-LHBS-file].[dbo].[spIO_OUT_FileSelect] @FileID
    -- SELECT FileContent = BinaryContent,
    --       [FileName] ,
    --       ContentType,
    --       Size
    --FROM [LMS-LHBS-file].[dbo].tblFileData
    --WHERE FileID = @FileID
END