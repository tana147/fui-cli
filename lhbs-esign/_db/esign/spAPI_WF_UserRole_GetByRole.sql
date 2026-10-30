CREATE PROCEDURE [dbo].[spAPI_WF_UserRole_GetByRole]
    @sys_UserID VARCHAR(50),
    @RolesID    INT
AS

BEGIN
    SET NOCOUNT ON;
    SELECT
        u.UserID,
        u.FullName,
        u.EmployeeCode,
        u.DepartmentName,
        u.Email,
        u.JobTitle
    FROM dbo.tblWF_UserRoles ur
    INNER JOIN dbo.tblWF_User u ON ur.EmployeeCode = u.EmployeeCode
    WHERE ur.RolesID = @RolesID
      AND ur.Enable = 1
      AND u.IsActive = 1
    ORDER BY u.FullName;
END
