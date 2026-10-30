CREATE PROCEDURE [dbo].[spAPI_WF_Request_SendForSigning]
    @ExecutionID BIGINT,
    @DocumentFileID UNIQUEIDENTIFIER,
    @DocumentFileName NVARCHAR(255) = NULL,
    @DocumentFileUrl NVARCHAR(500) = NULL,
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

        DECLARE @ResolvedUrl NVARCHAR(500) = ISNULL(
            NULLIF(LTRIM(RTRIM(@DocumentFileUrl)), ''),
            N'https://file.zentea.vn/iotdev/FileData/' + LTRIM(RTRIM(ISNULL(@DocumentFileID, '')))
        );

        -- Cập nhật thông tin file vào execution
        UPDATE dbo.tblWF_StepExecution
        SET DocumentFileID   = @DocumentFileID,
            DocumentFileName = ISNULL(NULLIF(LTRIM(RTRIM(@DocumentFileName)), ''), DocumentFileName),
            DocumentFileUrl  = @ResolvedUrl,
            UpdateUser       = @sys_UserID,
            UpdateTime       = GETDATE()
        WHERE ExecutionID = @ExecutionID
          AND [Enable] = 1;

        -- Đẩy trạng thái của Signer đầu tiên lên WAITING
        UPDATE dbo.tblWF_StepSignerExec
        SET Status = 'WAITING',
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
        WHERE ExecutionID = @ExecutionID
          AND SignerOrder = 1
          AND Status = 'PENDING'
          AND [Enable] = 1;

        -- Log Audit
        INSERT INTO dbo.tblWF_AuditLog
        (
            InstanceID, StepOrder, ActionCode, ActionDetail, UserID,
            CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable]
        )
        VALUES
        (
            @InstanceID, @StepOrder, 'SEND_FOR_SIGNING', N'Đã gửi hồ sơ đi ký số.', @sys_UserID,
            @sys_UserID, GETDATE(), NULL, NULL, 1
        );

        COMMIT TRANSACTION;

        SELECT CAST(1 AS BIT) AS Success, N'Gửi hồ sơ đi ký thành công.' AS Message;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message;
    END CATCH
END

