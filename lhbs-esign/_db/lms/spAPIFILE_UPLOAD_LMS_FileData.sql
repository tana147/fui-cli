CREATE PROC [dbo].[spAPIFILE_UPLOAD_LMS_FileData]
    @sys_UserID          VARCHAR(50),
    @sys_FileContent     VARBINARY(MAX),
    @sys_FileName        NVARCHAR(255),
    @sys_FileContentType VARCHAR(100),
    @sys_FileSize        BIGINT,
    @FileID              VARCHAR(32)   
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @NewFileID VARCHAR(32);
    -- Nếu không truyền FileID → tạo mới
    IF NULLIF(@FileID, '') IS NULL
        SET @NewFileID = REPLACE(CONVERT(VARCHAR(36), NEWID()), '-', '');
    ELSE
        SET @NewFileID = @FileID;

	INSERT into [dbo].[log_test_xxx](FileID) values(@FileID)

    BEGIN TRY
        BEGIN TRAN;

        IF NULLIF(@FileID, '') IS NULL
        BEGIN
            -- INSERT
            EXEC [LMS-LHBS-file].[dbo].[spIO_IN_FileInsert]
                 @FileID      = @NewFileID,
                 @FileData    = @sys_FileContent,
                 @FileName    = @sys_FileName,
                 @contentType = @sys_FileContentType,
                 @Size        = @sys_FileSize,
                 @CreateUser  = @sys_UserID;
        END
        ELSE
        BEGIN
            -- UPDATE (chỉ gọi proc update, không check tồn tại)
            EXEC [LMS-LHBS-file].[dbo].[spIO_IN_FileUpdate]
                 @FileID     = @NewFileID,
                 @FileData   = @sys_FileContent,
                 @FileName   = @sys_FileName,
                 @CreateUser = @sys_UserID;
        END

        COMMIT;

        -- Output thống nhất
        SELECT 
            FILE_ID          = @NewFileID,
            [FILE_NAME]      = @sys_FileName,
            FILE_CONTENTTYPE = @sys_FileContentType,
            FILE_SIZE        = @sys_FileSize,
            FILE_URL         = N'/FileData/' + @NewFileID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH
END
