CREATE PROCEDURE [dbo].[spAPI_WF_Request_CancelSigning]
    @ExecutionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @InstanceID BIGINT;
        DECLARE @StepOrder INT;
        DECLARE @StepType VARCHAR(20);

        SELECT @InstanceID = InstanceID, 
               @StepOrder = StepOrder,
               @StepType = StepType
        FROM dbo.tblWF_StepExecution
        WHERE ExecutionID = @ExecutionID
          AND [Enable] = 1
          AND Status = 'ACTIVE';

        IF @InstanceID IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy lượt thực thi bước đang hoạt động.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @StepType <> 'SIGN'
        BEGIN
            RAISERROR(N'Bước này không phải là bước ký số.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Kiểm tra xem đã có ai ký chưa
        IF EXISTS (
            SELECT 1 
            FROM dbo.tblWF_StepSignerExec
            WHERE ExecutionID = @ExecutionID 
              AND Status = 'SIGNED' 
              AND [Enable] = 1
        )
        BEGIN
            RAISERROR(N'Hồ sơ đã có chữ ký, không thể hủy gửi ký.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Xóa thông tin file đã tạo để đưa về trạng thái "Chưa gửi ký"
        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileID   = NULL,
            DocumentFileName = NULL,
            DocumentFileUrl  = NULL,
            UpdateUser       = @sys_UserID,
            UpdateTime       = GETDATE()
        WHERE ExecutionID = @ExecutionID
          AND [Enable] = 1;

        -- Đưa tất cả người ký trong lượt thực thi này về PENDING
        UPDATE dbo.tblWF_StepSignerExec
        SET Status = 'PENDING',
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE ExecutionID = @ExecutionID
          AND Status IN ('WAITING', 'PENDING')
          AND [Enable] = 1;

        -- Log Audit
        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @InstanceID, @StepOrder, 'CANCEL_SIGNING', N'Đã hủy gửi ký số.', @sys_UserID,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        );

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS Success, N'Hủy gửi ký thành công.' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

