CREATE PROCEDURE [dbo].[spAPI_WF_RoleMapping_GetList]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        RoleMappingID,
        RoleCode,
        RoleName,
        DefaultPersonID,
        DefaultPersonName,
        DepartmentName,
        IsActive,
        CreateUser,
        CreateTime,
        UpdateUser,
        UpdateTime
    FROM dbo.tblWF_RoleMapping
    WHERE [Enable] = 0
    ORDER BY RoleName, RoleCode;
END
