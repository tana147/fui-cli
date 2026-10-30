CREATE PROCEDURE [dbo].[spAPI_WF_User_GetPermissions]
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SELECT DISTINCT
        P.ModuleKey,
        P.ModuleName,
        P.FeatureGroup,
        P.PermissionKey,
        P.PermissionName
    FROM dbo.tblWF_Permissions P
    INNER JOIN dbo.tblWF_RolePermissions RP ON P.PermissionsID = RP.PermissionsID
    INNER JOIN dbo.tblWF_UserRoles UR ON RP.RolesID = UR.RolesID
    WHERE UR.EmployeeCode = @sys_UserID
      AND P.Enable = 1
      AND RP.Enable = 1
      AND UR.Enable = 1;
END
