
-- 8.3 ProjectMember_Delete — gỡ thành viên (không cho gỡ LEAD cuối cùng)
CREATE   PROCEDURE [dbo].[spAPI_WF_ProjectMember_Delete]
    @sys_UserID VARCHAR(9),
    @ProjectID  BIGINT,
    @EmployeeCode VARCHAR(9)
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

        -- Không cho gỡ LEAD cuối cùng
        IF EXISTS (SELECT 1 FROM dbo.tblWF_ProjectMember WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode AND Role = 'LEAD' AND [Enable] = 1)
           AND (SELECT COUNT(1) FROM dbo.tblWF_ProjectMember WHERE ProjectID = @ProjectID AND Role = 'LEAD' AND [Enable] = 1) <= 1
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không thể gỡ LEAD cuối cùng của project.' AS Message;
            RETURN;
        END

        UPDATE dbo.tblWF_ProjectMember
        SET [Enable] = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ProjectID = @ProjectID AND EmployeeCode = @EmployeeCode;

        SELECT CAST(1 AS BIT) AS Success, N'Đã gỡ thành viên.' AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

