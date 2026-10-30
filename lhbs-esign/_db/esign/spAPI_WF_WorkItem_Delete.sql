
-- Soft delete (Enable = 0)
CREATE PROCEDURE [dbo].[spAPI_WF_WorkItem_Delete]
    @sys_UserID VARCHAR(9),
    @WorkItemID BIGINT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Nhiệm vụ không tồn tại hoặc đã xóa.' AS Message
            RETURN
        END

        -- Check permission
        DECLARE @ProjectID BIGINT
        SELECT @ProjectID = ProjectID FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID AND [Enable] = 1

        DECLARE @IsLead INT = CASE WHEN EXISTS (
            SELECT 1 FROM dbo.tblWF_ProjectMember
            WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND Role = 'LEAD' AND [Enable] = 1
        ) THEN 1 ELSE 0 END

        -- Chỉ LEAD hoặc người tạo hoặc admin mới xóa được
        DECLARE @CreateUser VARCHAR(9)
        SELECT @CreateUser = CreateUser FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID

        IF @IsLead = 0
           AND @CreateUser <> @sys_UserID
           AND dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền xóa nhiệm vụ này.' AS Message
            RETURN
        END

        UPDATE dbo.tblWF_WorkItem
        SET [Enable]   = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE WorkItemID = @WorkItemID

        SELECT CAST(1 AS BIT) AS Success, N'Đã xóa nhiệm vụ.' AS Message, @WorkItemID AS WorkItemID
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message
    END CATCH
END

