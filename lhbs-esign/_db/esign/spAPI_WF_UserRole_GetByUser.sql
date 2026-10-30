CREATE PROCEDURE [dbo].[spAPI_WF_UserRole_GetByUser]
    @sys_UserID VARCHAR(50),
    @UserID     VARCHAR(50)
AS
BEGIN
    SELECT 
        ur.RolesID,
        r.Name,
        r.Description
    FROM dbo.tblWF_UserRoles ur
    INNER JOIN dbo.tblWF_Roles r ON ur.RolesID = r.RolesID
    WHERE ur.EmployeeCode = @UserID;
END
