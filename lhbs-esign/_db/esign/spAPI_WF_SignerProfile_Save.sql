CREATE PROCEDURE [dbo].[spAPI_WF_SignerProfile_Save]
    @UserID INT = 0,
    @sys_UserID VARCHAR(50),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LegacyUserID         INT              = TRY_CAST(JSON_VALUE(@sys_RawData, '$.LegacyUserID') AS INT);
    DECLARE @FullName             NVARCHAR(200)    = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.FullName'), N'')));
    DECLARE @Email                VARCHAR(200)     = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.Email'), ''))), '');
    DECLARE @EmployeeCode         VARCHAR(50)      = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.EmployeeCode'), ''))), '');
    DECLARE @IsInternalUser       BIT              = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsInternalUser') AS BIT), 1);
    DECLARE @JobTitle             NVARCHAR(200)    = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.JobTitle'), N''))), N'');
    DECLARE @DepartmentName       NVARCHAR(250)    = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.DepartmentName'), N''))), N'');
    DECLARE @CertSerial           VARCHAR(128)     = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.CertSerial'), ''))), '');
    DECLARE @CertSubject          NVARCHAR(1000)   = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.CertSubject'), N''))), N'');
    DECLARE @CertIssuer           NVARCHAR(300)    = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.CertIssuer'), N''))), N'');
    DECLARE @CertValidFrom        DATETIME         = TRY_CAST(JSON_VALUE(@sys_RawData, '$.CertValidFrom') AS DATETIME);
    DECLARE @CertValidTo          DATETIME         = TRY_CAST(JSON_VALUE(@sys_RawData, '$.CertValidTo') AS DATETIME);
    DECLARE @CertIsActive         BIT              = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.CertIsActive') AS BIT), 1);
    DECLARE @SignatureDisplayName NVARCHAR(200)    = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignatureDisplayName'), N''))), N'');
    DECLARE @SignatureFileID      UNIQUEIDENTIFIER = TRY_CAST(JSON_VALUE(@sys_RawData, '$.SignatureFileID') AS UNIQUEIDENTIFIER); -- was VARCHAR(80)
    DECLARE @SignatureNote        NVARCHAR(1000)   = NULLIF(LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.SignatureNote'), N''))), N'');
    DECLARE @IsActive             BIT              = ISNULL(TRY_CAST(JSON_VALUE(@sys_RawData, '$.IsActive') AS BIT), 1);

    IF @FullName = N''
    BEGIN
        RAISERROR(N'Họ tên người dùng không được để trống.', 16, 1);
        RETURN;
    END

    IF @Email IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.tblWF_User WHERE [Enable] = 1 AND UserID <> ISNULL(@UserID, 0) AND Email = @Email)
    BEGIN
        RAISERROR(N'Email đã tồn tại trong danh sách người dùng ký.', 16, 1);
        RETURN;
    END

    IF @CertSerial IS NOT NULL
       AND EXISTS (SELECT 1 FROM dbo.tblWF_User WHERE [Enable] = 0 AND UserID <> ISNULL(@UserID, 0) AND CertSerial = @CertSerial)
    BEGIN
        RAISERROR(N'Serial chứng thư đã tồn tại.', 16, 1);
        RETURN;
    END

    IF ISNULL(@UserID, 0) <= 0
    BEGIN
        INSERT INTO dbo.tblWF_User
        (
            LegacyUserID, FullName, Email, EmployeeCode, IsInternalUser, JobTitle, DepartmentName,
            CertSerial, CertSubject, CertIssuer, CertValidFrom, CertValidTo, CertIsActive,
            SignatureDisplayName, SignatureFileID, SignatureNote, IsActive,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @LegacyUserID, @FullName, @Email, @EmployeeCode, @IsInternalUser, @JobTitle, @DepartmentName,
            @CertSerial, @CertSubject, @CertIssuer, @CertValidFrom, @CertValidTo, @CertIsActive,
            @SignatureDisplayName, @SignatureFileID, @SignatureNote, @IsActive,
            @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1
        );
        SET @UserID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_User
        SET LegacyUserID        = @LegacyUserID,
            FullName            = @FullName,
            Email               = @Email,
            EmployeeCode        = @EmployeeCode,
            IsInternalUser      = @IsInternalUser,
            JobTitle            = @JobTitle,
            DepartmentName      = @DepartmentName,
            CertSerial          = @CertSerial,
            CertSubject         = @CertSubject,
            CertIssuer          = @CertIssuer,
            CertValidFrom       = @CertValidFrom,
            CertValidTo         = @CertValidTo,
            CertIsActive        = @CertIsActive,
            SignatureDisplayName = @SignatureDisplayName,
            SignatureFileID     = @SignatureFileID,
            SignatureNote       = @SignatureNote,
            IsActive            = @IsActive,
            UpdateUser          = @sys_UserID,
            UpdateTime          = GETDATE()
        WHERE UserID = @UserID AND [Enable] = 1;
    END

    SELECT Message = N'Lưu hồ sơ người ký thành công.', UserID = @UserID;
END
