CREATE PROCEDURE [dbo].[spAPI_LMS_FileData_Delete]
    @sys_UserID VARCHAR(50),
    @FileID VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NULLIF(@FileID, '') IS NULL
    BEGIN
        RAISERROR(N'FileID không được để trống.', 16, 1);
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM dbo.FileData WHERE FileID = @FileID)
    BEGIN
        DELETE dbo.FileData
        WHERE FileID = @FileID;

        SELECT
            FILE_ID = @FileID,
            DELETED = CAST(1 AS bit),
            STORAGE = 'LMS.dbo.FileData';
        RETURN;
    END;

    EXEC [LMS-LHBS-file].[dbo].[spIO_IN_FileDelete]
        @FileID = @FileID;

    SELECT
        FILE_ID = @FileID,
        DELETED = CAST(1 AS bit),
        STORAGE = 'LMS-LHBS-file';
END
