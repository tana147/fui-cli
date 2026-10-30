
-- 7.4 Project_Delete — soft delete (LEAD hoặc project-manage)
CREATE   PROCEDURE [dbo].[spAPI_WF_Project_Delete]
    @sys_UserID VARCHAR(9),
    @ProjectID  BIGINT
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
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền xóa project này.' AS Message;
            RETURN;
        END
        -- Còn workflow đang gắn → chặn xóa để tránh mồ côi
        IF EXISTS (SELECT 1 FROM dbo.tblWF_Definition WHERE ProjectID = @ProjectID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Không thể xóa: vẫn còn quy trình thuộc project này. Hãy gỡ hoặc lưu trữ (ARCHIVED) thay vì xóa.' AS Message;
            RETURN;
        END

        UPDATE dbo.tblWF_Project SET [Enable] = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ProjectID = @ProjectID;

        SELECT CAST(1 AS BIT) AS Success, N'Đã xóa project.' AS Message;
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END
