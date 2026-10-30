CREATE PROCEDURE [dbo].[spAPI_WF_Permission_GetList]
    @sys_UserID VARCHAR(50),
    @ModuleKey  VARCHAR(50) = NULL
AS
BEGIN
    SELECT
        PermissionsID, 
        ModuleKey, 
        ModuleName, 
        FeatureGroup, 
        PermissionKey, 
        PermissionName, 
        Enable,
        CreateTime, 
        UpdateUser, 
        UpdateTime
    FROM dbo.tblWF_Permissions
    WHERE (
        @ModuleKey IS NULL 
        OR @ModuleKey = '' 
        OR @ModuleKey = 'NULL' 
        OR ModuleKey = @ModuleKey
    )
    ORDER BY ModuleKey, FeatureGroup, PermissionKey;
END

