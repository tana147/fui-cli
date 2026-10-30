CREATE PROCEDURE [dbo].[spAPI_WF_Employee_Search]
    @SearchText NVARCHAR(100) = '',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tìm kiếm theo Tên, Mã nhân viên hoặc Email
    SELECT TOP 20
        EmployeeID = EmployeeCode, -- Hoặc SignerProfileID tùy theo cách bạn map
        FullName,
        EmployeeCode,
        Email,
        JobTitle,
        DepartmentName,
        Label = FullName + ' (' + EmployeeCode + ') - ' + ISNULL(DepartmentName, '')
    FROM dbo.tblWF_User
    WHERE [Enable] = 1
      AND (
        FullName LIKE '%' + @SearchText + '%'
        OR EmployeeCode LIKE '%' + @SearchText + '%'
        OR Email LIKE '%' + @SearchText + '%'
      )
    ORDER BY FullName;
END
