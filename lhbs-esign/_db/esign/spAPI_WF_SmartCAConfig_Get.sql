CREATE PROCEDURE [dbo].[spAPI_WF_SmartCAConfig_Get]
    @sys_UserID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Endpoint = MAX(CASE WHEN ConfigKey = 'Endpoint' THEN ConfigValue END),
        ApiKey = MAX(CASE WHEN ConfigKey = 'ApiKey' THEN ConfigValue END),
        UploadApi = MAX(CASE WHEN ConfigKey = 'UploadApi' THEN ConfigValue END),
        DefaultOptionSign = MAX(CASE WHEN ConfigKey = 'DefaultOptionSign' THEN ConfigValue END),
        LastUpdateUser = MAX(UpdateUser),
        LastUpdateTime = MAX(UpdateTime)
    FROM dbo.tblWF_SmartCAConfig
    WHERE [Enable] = 0
      AND IsActive = 1;

    SELECT
        ConfigID,
        ConfigKey,
        ConfigValue,
        Description,
        IsActive,
        UpdateUser,
        UpdateTime
    FROM dbo.tblWF_SmartCAConfig
    WHERE [Enable] = 0
    ORDER BY ConfigKey;
END;
