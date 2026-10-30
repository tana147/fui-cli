CREATE PROCEDURE [dbo].[spAPI_WF_InstanceTask_UpdateStatus]
    @sys_UserID VARCHAR(9),
    @TaskID     BIGINT,
    @Status     VARCHAR(20) -- 'TODO' hoặc 'DONE'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @Status NOT IN ('TODO', 'DONE')
        BEGIN
            SELECT 0 AS Success, N'Status không hợp lệ, chỉ chấp nhận TODO hoặc DONE' AS Message;
            RETURN;
        END

        DECLARE @InstanceID BIGINT;
        SELECT @InstanceID = InstanceID FROM dbo.tblWF_InstanceTask WHERE TaskID = @TaskID;

        UPDATE dbo.tblWF_InstanceTask
        SET Status     = @Status,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE TaskID  = @TaskID
          AND [Enable] = 1;

        IF @@ROWCOUNT = 0
        BEGIN
            SELECT 0 AS Success, N'Không tìm thấy nhiệm vụ hoặc đã bị xóa' AS Message;
            RETURN;
        END

        -- ── Kích hoạt tự động hóa ──────────────────────────────────────────────
        IF @Status = 'DONE'
        BEGIN
            EXEC dbo.spAPI_WF_Automation_Execute
                @sys_UserID = @sys_UserID,
                @InstanceID = @InstanceID,
                @Event = 'SUBTASK_DONE',
                @InternalCall = 1;
        END

        SELECT 1 AS Success, N'Cập nhật trạng thái thành công' AS Message;
    END TRY
    BEGIN CATCH
        SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

