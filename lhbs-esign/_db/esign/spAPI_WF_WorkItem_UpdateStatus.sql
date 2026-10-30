
-- Đổi trạng thái 1 WorkItem (dùng khi kéo Board)
CREATE PROCEDURE [dbo].[spAPI_WF_WorkItem_UpdateStatus]
    @sys_UserID     VARCHAR(9),
    @WorkItemID     BIGINT,
    @Status         VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        -- Validate status
        IF @Status NOT IN ('BACKLOG', 'TODO', 'IN_PROGRESS', 'DONE', 'BLOCKED')
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Status không hợp lệ: ' + ISNULL(@Status, 'NULL') AS Message
            RETURN
        END

        IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID AND [Enable] = 1)
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Nhiệm vụ không tồn tại hoặc đã xóa.' AS Message
            RETURN
        END

        -- Check permission: thành viên project hoặc admin
        DECLARE @ProjectID BIGINT
        SELECT @ProjectID = ProjectID FROM dbo.tblWF_WorkItem WHERE WorkItemID = @WorkItemID AND [Enable] = 1

        IF dbo.fnWF_CheckPermission(@sys_UserID, 'admin-all,project-manage') = 0
           AND NOT EXISTS (
               SELECT 1 FROM dbo.tblWF_ProjectMember
               WHERE ProjectID = @ProjectID AND EmployeeCode = @sys_UserID AND [Enable] = 1
           )
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'Bạn không có quyền thao tác.' AS Message
            RETURN
        END

        UPDATE dbo.tblWF_WorkItem
        SET Status     = @Status,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE WorkItemID = @WorkItemID AND [Enable] = 1

        SELECT CAST(1 AS BIT) AS Success, N'Đã chuyển trạng thái.' AS Message, @WorkItemID AS WorkItemID
    END TRY
    BEGIN CATCH
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message
    END CATCH
END
