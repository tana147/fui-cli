
CREATE PROCEDURE [dbo].[spAPI_WF_UserRole_Search]
    @SearchText NVARCHAR(200) = '',
    @RoleCode VARCHAR(50) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        AssignmentID,
        RoleCode,
        EmployeeCode,
        FullName,
        DepartmentName,
        DisplayName = FullName + ' (' + EmployeeCode + ') - ' + ISNULL(DepartmentName, N'N/A')
    FROM dbo.tblWF_UserRoleAssignment
    WHERE [Enable] = 1
      AND IsActive = 1
      AND (@RoleCode IS NULL OR RoleCode = @RoleCode)
      AND (
          @SearchText = ''
          OR FullName LIKE '%' + @SearchText + '%'
          OR EmployeeCode LIKE '%' + @SearchText + '%'
          OR RoleCode LIKE '%' + @SearchText + '%'
      )
    ORDER BY RoleCode, FullName;
END

