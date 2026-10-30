CREATE PROCEDURE [dbo].[spAPI_WF_StepExecution_UpdateStatus]
    @sys_UserID VARCHAR(50),
    @InstanceID BIGINT,
    @Status VARCHAR(20) -- 'ACTIVE' hoặc 'DONE'
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Tìm ExecutionID hiện hành đang chạy của Instance
        DECLARE @ExecutionID BIGINT;
        SELECT TOP 1 @ExecutionID = EX.ExecutionID
        FROM dbo.tblWF_StepExecution AS EX
        INNER JOIN dbo.tblWF_Instance AS I ON I.InstanceID = EX.InstanceID
        WHERE EX.InstanceID = @InstanceID
          AND EX.StepOrder = I.CurrentStepOrder
          AND EX.[Enable] = 1
        ORDER BY EX.ExecutionID DESC;

        IF @ExecutionID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy bước thực thi hiện tại.', 16, 1);
            RETURN;
        END

        BEGIN TRANSACTION;

        -- Cập nhật trạng thái của bước thực thi
        UPDATE dbo.tblWF_StepExecution
        SET Status = @Status,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE ExecutionID = @ExecutionID;

        -- Đồng thời, nếu trạng thái chuyển sang DONE, có thể ghi nhận audit log hoặc cập nhật AssigneeExec tương ứng
        DECLARE @CurrentStepOrder INT;
        SELECT @CurrentStepOrder = StepOrder FROM dbo.tblWF_StepExecution WHERE ExecutionID = @ExecutionID;

        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, [Enable]
        )
        VALUES
        (
            @InstanceID, @CurrentStepOrder, CASE WHEN @Status = 'DONE' THEN 'STEP_DONE' ELSE 'STEP_ACTIVE' END, 
            CASE WHEN @Status = 'DONE' THEN N'Người dùng báo hoàn thành xử lý bước.' ELSE N'Người dùng thu hồi trạng thái hoàn thành bước.' END, 
            @sys_UserID, @sys_UserID, GETDATE(), 1
        );

        COMMIT TRANSACTION;

        SELECT 1 AS Success, N'Cập nhật trạng thái thành công.' AS Message, @InstanceID AS InstanceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END