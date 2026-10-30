CREATE FUNCTION [dbo].[fnWF_CheckPermission] (
    @sys_UserID VARCHAR(9),
    @PermissionKeys VARCHAR(500) -- Nhận danh sách các key cách nhau bằng dấu phẩy, ví dụ: 'nhan-su-xem,admin-all'
)
RETURNS INT
AS
BEGIN
    DECLARE @HasPermission INT = 0;

    -- Kiểm tra xem user có ít nhất một trong các key truyền vào hay không
    IF EXISTS (
        SELECT 1 
        FROM dbo.tblWF_Permissions P
        INNER JOIN dbo.tblWF_RolePermissions RP ON P.PermissionsID = RP.PermissionsID
        INNER JOIN dbo.tblWF_UserRoles UR ON RP.RolesID = UR.RolesID
        INNER JOIN STRING_SPLIT(@PermissionKeys, ',') S ON P.PermissionKey = LTRIM(RTRIM(S.value))
        WHERE UR.EmployeeCode = @sys_UserID
          AND P.Enable = 1
          AND RP.Enable = 1
          AND UR.Enable = 1
    )
    BEGIN
        SET @HasPermission = 1;
    END

    RETURN @HasPermission;
END

