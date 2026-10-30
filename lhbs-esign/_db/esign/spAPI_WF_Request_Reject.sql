CREATE PROCEDURE [dbo].[spAPI_WF_Request_Reject]
    @InstanceID BIGINT,
    @SignerExecID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RejectReason NVARCHAR(500) = ISNULL(JSON_VALUE(@sys_RawData, '$.RejectReason'), N'Không có lý do.');
    DECLARE @OtpCode VARCHAR(32) = LTRIM(RTRIM(ISNULL(JSON_VALUE(@sys_RawData, '$.OtpCode'), '')));
    DECLARE @MaskedOtpSuffix VARCHAR(8) = '';
    DECLARE @ResolvedSignerExecID BIGINT = 0;
    DECLARE @ExecutionID BIGINT = 0;
    DECLARE @CurrentStepOrder INT = 0;
    DECLARE @CurrentSignerMethodRaw VARCHAR(100) = '';
    DECLARE @CurrentSignerMethod VARCHAR(100) = '';

    SET @RejectReason = LTRIM(RTRIM(ISNULL(@RejectReason, N'')));
    IF @RejectReason = N''
        SET @RejectReason = N'Không có lý do.';

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (
            SELECT 1
            FROM dbo.tblWF_Instance
            WHERE InstanceID = @InstanceID
              AND [Enable] = 1
        )
        BEGIN
            RAISERROR(N'Không tìm thấy yêu cầu ký.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF ISNULL(@SignerExecID, 0) > 0
        BEGIN
            SELECT TOP (1)
                @ResolvedSignerExecID = SE.SignerExecID,
                @ExecutionID = SE.ExecutionID
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX
                ON EX.ExecutionID = SE.ExecutionID
               AND EX.[Enable] = 1
            WHERE SE.SignerExecID = @SignerExecID
              AND EX.InstanceID = @InstanceID
              AND EX.Status IN ('ACTIVE', 'SIGNING')
              AND SE.Status = 'WAITING'
              AND SE.ResolvedPersonID = @sys_UserID
              AND SE.[Enable] = 1;
        END

        IF ISNULL(@ResolvedSignerExecID, 0) = 0
        BEGIN
            SELECT TOP (1)
                @ResolvedSignerExecID = SE.SignerExecID,
                @ExecutionID = SE.ExecutionID
            FROM dbo.tblWF_StepSignerExec AS SE
            INNER JOIN dbo.tblWF_StepExecution AS EX
                ON EX.ExecutionID = SE.ExecutionID
               AND EX.[Enable] = 1
            WHERE EX.InstanceID = @InstanceID
              AND EX.Status IN ('ACTIVE', 'SIGNING')
              AND SE.Status = 'WAITING'
              AND SE.ResolvedPersonID = @sys_UserID
              AND SE.[Enable] = 1
            ORDER BY EX.StepOrder, SE.SignerOrder;
        END

        IF ISNULL(@ResolvedSignerExecID, 0) = 0
        BEGIN
            RAISERROR(N'Không tìm thấy lượt ký hiện tại của người dùng.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @CurrentStepOrder = EX.StepOrder
        FROM dbo.tblWF_StepExecution AS EX
        WHERE EX.ExecutionID = @ExecutionID
          AND EX.[Enable] = 1;

        SELECT TOP (1)
            @CurrentSignerMethodRaw = ISNULL(SE.SignMethod, '')
        FROM dbo.tblWF_StepSignerExec AS SE
        WHERE SE.SignerExecID = @ResolvedSignerExecID
          AND SE.[Enable] = 1;

        SET @CurrentSignerMethod = LOWER(@CurrentSignerMethodRaw);
        IF @CurrentSignerMethod IN ('otp_email', 'otp_sms')
        BEGIN
            IF @OtpCode = ''
            BEGIN
                RAISERROR(N'Bước ký OTP yêu cầu mã xác thực OTP.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            IF @OtpCode LIKE '%[^0-9A-Za-z]%' OR LEN(@OtpCode) < 4 OR LEN(@OtpCode) > 12
            BEGIN
                RAISERROR(N'Mã OTP không hợp lệ. Vui lòng nhập 4-12 ký tự chữ/số.', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            SET @MaskedOtpSuffix = CASE WHEN LEN(@OtpCode) >= 2 THEN RIGHT(@OtpCode, 2) ELSE @OtpCode END;
            SET @RejectReason = REPLACE(@RejectReason, @OtpCode, N'****' + @MaskedOtpSuffix);
        END

        UPDATE dbo.tblWF_StepSignerExec
        SET Status = CASE WHEN SignerExecID = @ResolvedSignerExecID THEN 'REJECTED' ELSE 'CANCELLED' END,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ExecutionID = @ExecutionID
          AND [Enable] = 1
          AND Status IN ('WAITING', 'PENDING');

        UPDATE dbo.tblWF_StepExecution
        SET Status = 'REJECTED',
            RejectedBy = @sys_UserID,
            RejectedReason = @RejectReason,
            RejectedDate = GETDATE(),
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE ExecutionID = @ExecutionID
          AND [Enable] = 1;

        UPDATE dbo.tblWF_Instance
        SET Status = 'REJECTED',
            CurrentStepOrder = @CurrentStepOrder,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1;

        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @InstanceID, @CurrentStepOrder, 'REJECTED', @RejectReason, @sys_UserID,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        );

        COMMIT TRANSACTION;

        -- Kích hoạt tự động hóa khi chuyển trạng thái hoặc từ chối
        EXEC dbo.spAPI_WF_Automation_Execute
            @sys_UserID = @sys_UserID,
            @InstanceID = @InstanceID,
            @Event = 'STAGE_CHANGED',
            @sys_InternalCall = 1;

        EXEC dbo.spAPI_WF_Request_GetDetail @InstanceID = @InstanceID, @sys_UserID = @sys_UserID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH;
END
