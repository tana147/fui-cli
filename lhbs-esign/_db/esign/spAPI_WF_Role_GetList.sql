CREATE PROCEDURE [dbo].[spAPI_WF_Role_GetList]
    @sys_UserID VARCHAR(50),
    @Keyword    NVARCHAR(100) = NULL,
    @Enable     TINYINT = NULL -- NULL: Lấy hết, 1: Active, 0: Disable
AS

BEGIN
    SELECT
        r.RolesID, r.Name, r.Description, r.Enable,
        r.CreateTime, r.UpdateUser, r.UpdateTime,
        UserCount = (
            SELECT COUNT(DISTINCT ur.EmployeeCode)
            FROM dbo.tblWF_UserRoles ur
            INNER JOIN dbo.tblWF_User u ON ur.EmployeeCode = u.EmployeeCode
            WHERE ur.RolesID = r.RolesID
              AND ur.Enable = 1
              AND u.IsActive = 1
        )

    FROM dbo.tblWF_Roles r
    WHERE (@Keyword IS NULL OR r.Name LIKE '%' + @Keyword + '%' OR r.Description LIKE '%' + @Keyword + '%')
      AND (@Enable IS NULL OR r.Enable = @Enable)
    ORDER BY r.Name ASC;
END




