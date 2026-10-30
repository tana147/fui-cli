CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_SaveMyConfig]
    @sys_UserID  VARCHAR(50),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserID               INT              = NULL;
    DECLARE @SmartCAOptionSign    VARCHAR(5)       = CASE WHEN ISNULL(JSON_VALUE(@sys_RawData, '$.SmartCAOptionSign'), '') IN ('0', '1') THEN JSON_VALUE(@sys_RawData, '$.SmartCAOptionSign') ELSE '1' END;
    DECLARE @SignatureDisplayName NVARCHAR(200)    = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignatureDisplayName'), N''))), N'');
    DECLARE @SignatureFileID      UNIQUEIDENTIFIER = TRY_CAST(JSON_VALUE(@sys_RawData, '$.SignatureFileID') AS UNIQUEIDENTIFIER); -- was VARCHAR(80)
    DECLARE @SignatureNote        NVARCHAR(1000)   = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignatureNote'), N''))), N'');

    SELECT TOP (1) @UserID = UserID
    FROM dbo.tblWF_User
    WHERE [Enable] = 1 AND IsActive = 1
      AND (EmployeeCode = @sys_UserID OR Email = @sys_UserID OR CAST(LegacyUserID AS VARCHAR(50)) = @sys_UserID)
    ORDER BY
        CASE WHEN EmployeeCode = @sys_UserID THEN 0
             WHEN Email = @sys_UserID THEN 1
             WHEN CAST(LegacyUserID AS VARCHAR(50)) = @sys_UserID THEN 2
             ELSE 9 END,
        UserID DESC;

    IF ISNULL(@UserID, 0) <= 0
    BEGIN
        RAISERROR(N'Không tìm thấy hồ sơ người dùng đang hoạt động của bạn. Vui lòng liên hệ quản trị để cập nhật hồ sơ.', 16, 1);
        RETURN;
    END

    UPDATE dbo.tblWF_User
    SET SmartCAOptionSign    = @SmartCAOptionSign,
        SignatureDisplayName = @SignatureDisplayName,
        SignatureFileID      = @SignatureFileID,
        SignatureNote        = @SignatureNote,
        UpdateUser           = @sys_UserID,
        UpdateTime           = GETDATE()
    WHERE UserID = @UserID AND [Enable] = 1;

    SELECT Message = N'Lưu cấu hình chữ ký của tôi thành công.',
           UserID = @UserID,
           SmartCAOptionSign = @SmartCAOptionSign;
END
