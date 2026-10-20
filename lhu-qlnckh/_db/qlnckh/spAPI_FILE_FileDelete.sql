CREATE PROCEDURE [dbo].[spAPIFILE_FileDelete]
    @FileID CHAR(32)
AS
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM dbo.FileData WHERE FileID = @FileID)
            BEGIN
                RAISERROR(N'File không tồn tại hoặc đã bị xoá', 16, 1);
                RETURN 0;
            END;
        DELETE FROM dbo.FileData WHERE FileID = @FileID;
    END;