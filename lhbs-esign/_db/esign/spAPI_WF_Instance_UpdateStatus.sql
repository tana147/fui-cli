CREATE PROCEDURE [dbo].[spAPI_WF_Instance_UpdateStatus]
    @sys_UserID VARCHAR(9),
    @InstanceID BIGINT,
    @StatusID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.tblWF_Instance WHERE InstanceID = @InstanceID AND [Enable] = 1)
        BEGIN
            RAISERROR(N'Không tìm thấy luồng công việc hoặc đã bị xóa.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        DECLARE @CurrentStepOrder INT = 0;
        SELECT @CurrentStepOrder = CurrentStepOrder FROM dbo.tblWF_Instance WHERE InstanceID = @InstanceID;

        -- Cập nhật trạng thái Instance
        UPDATE dbo.tblWF_Instance
        SET Status = @StatusID,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1;

        -- Nếu trạng thái là CANCELLED, hủy các lượt ký và bước ký hiện tại đang chạy
        IF @StatusID = 'CANCELLED'
        BEGIN
            -- Hủy lượt ký của những người ký đang chờ/chưa ký ở bước hiện tại
            UPDATE SE
            SET SE.Status = 'CANCELLED',
                SE.UpdateUser = @sys_UserID,
                SE.UpdateTime = GETDATE()
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = SE.ExecutionID
            WHERE EX.InstanceID = @InstanceID
              AND EX.[Enable] = 1
              AND SE.Status IN ('WAITING', 'PENDING')
              AND SE.[Enable] = 1;

            -- Hủy bước thực thi đang chạy
            UPDATE dbo.tblWF_StepExecution
            SET Status = 'CANCELLED',
                UpdateUser = @sys_UserID,
                UpdateTime = GETDATE()
            WHERE InstanceID = @InstanceID
              AND Status IN ('ACTIVE', 'SIGNING')
              AND [Enable] = 1;

            -- Ghi log audit
            INSERT INTO dbo.tblWF_AuditLog
            (
                InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
                CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
            )
            VALUES
            (
                @InstanceID, @CurrentStepOrder, 'CANCELLED', N'Người dùng hủy luồng công việc.', @sys_UserID,
                @sys_UserID, GETDATE(), NULL, NULL, 1
            );
        END

        COMMIT TRANSACTION;

        SELECT 1 AS Success, N'Cập nhật trạng thái thành công.' AS Message, @InstanceID AS InstanceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
