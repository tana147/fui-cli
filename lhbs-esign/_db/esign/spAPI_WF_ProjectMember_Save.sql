
-- 8.2 ProjectMember_Save — thêm/đổi role (LEAD hoặc project-manage)
CREATE   PROCEDURE [dbo].[spAPI_WF_ProjectMember_Save]
    @sys_UserID   VARCHAR(9),
    @ProjectID    BIGINT,
    @EmployeeCode VARCHAR(9),
    @Role         VARCHAR(20) = 'MEMBER'  -- LEAD | MEMBER | VIEWER
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @IsLead INT = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.tblWF_ProjectMember
            WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND Role = 'LEAD' AND [Enable] = 1
        ) THEN 1 ELSE 0 END;
        IF @IsLead = 0 AND dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền quản lý thành viên project này.' AS Message;
            RETURN;
        END
        IF @Role NOT IN ('LEAD', 'MEMBER', 'VIEWER')
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Vai trò không hợp lệ.' AS Message;
            RETURN;
        END

        DECLARE @FullName NVARCHAR(200);
        SELECT TOP 1 @FullName = FullName FROM dbo.tblWF_User WHERE EmployeeCode = @EmployeeCode AND [Enable] = 1;

        IF EXISTS (SELECT 1 FROM dbo.tblWF_ProjectMember WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode)
            UPDATE dbo.tblWF_ProjectMember
            SET Role = @Role, [Enable] = 1, FullName = ISNULL(@FullName, FullName),
                UpdateUser = @sys_UserID, UpdateTime = GETDATE()
            WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode;
        ELSE
            INSERT INTO dbo.tblWF_ProjectMember (ProjectID, EmployeeCode, FullName, Role, [Enable], CreateUser, CreateTime)
            VALUES (@ProjectID, @EmployeeCode, ISNULL(@FullName, @EmployeeCode), @Role, 1, @sys_UserID, GETDATE());

        SELECT CAST(1 AS BIT) AS Success, N'Đã lưu thành viên.' AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
