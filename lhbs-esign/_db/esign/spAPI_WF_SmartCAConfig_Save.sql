CREATE PROCEDURE [dbo].[spAPI_WF_SmartCAConfig_Save]
    @Endpoint NVARCHAR(1000) = NULL,
    @ApiKey NVARCHAR(1000) = NULL,
    @UploadApi NVARCHAR(200) = NULL,
    @DefaultOptionSign VARCHAR(5) = NULL,
    @sys_UserID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UseUser VARCHAR(50) = NULLIF(LTRIM(RTRIM(ISNULL(@sys_UserID, ''))), '');
    IF @UseUser IS NULL SET @UseUser = 'SYSTEM';

    DECLARE @Items TABLE
    (
        ConfigKey VARCHAR(100) NOT NULL,
        ConfigValue NVARCHAR(MAX) NULL,
        Description NVARCHAR(500) NULL
    );

    INSERT INTO @Items(ConfigKey, ConfigValue, Description)
    VALUES
        ('Endpoint', NULLIF(LTRIM(RTRIM(ISNULL(@Endpoint, ''))), ''), N'SmartCA ký nội bộ endpoint'),
        ('ApiKey', ISNULL(@ApiKey, N''), N'X-API-KEY gọi SmartCA'),
        ('UploadApi', NULLIF(LTRIM(RTRIM(ISNULL(@UploadApi, ''))), ''), N'API upload file đã ký về hệ thống'),
        ('DefaultOptionSign', CASE WHEN ISNULL(@DefaultOptionSign, '') IN ('0', '1') THEN @DefaultOptionSign ELSE '1' END, N'0=text, 1=image');

    MERGE dbo.tblWF_SmartCAConfig AS T
    USING @Items AS S
       ON T.ConfigKey = S.ConfigKey
      AND T.[Enable] = 0
    WHEN MATCHED THEN
      UPDATE SET
          T.ConfigValue = S.ConfigValue,
          T.Description = S.Description,
          T.IsActive = 1,
          T.UpdateUser = @UseUser,
          T.UpdateTime = GETDATE()
    WHEN NOT MATCHED THEN
      INSERT (ConfigKey, ConfigValue, Description, IsActive, UpdateUser, UpdateTime, [Enable])
      VALUES (S.ConfigKey, S.ConfigValue, S.Description, 1, @UseUser, GETDATE(), 0);

    SELECT
        Message = N'Lưu SmartCA config thành công.',
        UpdateUser = @UseUser,
        UpdateTime = GETDATE();
END;
