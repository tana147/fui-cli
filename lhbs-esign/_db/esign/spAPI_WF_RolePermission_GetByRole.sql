CREATE PROCEDURE [dbo].[spAPI_WF_RolePermission_GetByRole]
    @sys_UserID VARCHAR(50),
    @RolesID    INT
AS
BEGIN
    SELECT
        P.PermissionsID, 
        P.ModuleKey, 
        P.ModuleName, 
        P.FeatureGroup, 
        P.PermissionKey, 
        P.PermissionName
    FROM dbo.tblWF_RolePermissions RP
    INNER JOIN dbo.tblWF_Permissions P ON RP.PermissionsID = P.PermissionsID
    WHERE RP.RolesID = @RolesID AND RP.Enable = 1 AND P.Enable = 1;
END
