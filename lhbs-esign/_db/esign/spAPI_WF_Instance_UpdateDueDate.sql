
    CREATE PROCEDURE [dbo].[spAPI_WF_Instance_UpdateDueDate]
        @sys_UserID  VARCHAR(9),
        @InstanceID  BIGINT,
        @StepDueDate DATETIME,
        @StepStartDate DATETIME = NULL
    AS
    BEGIN
        SET NOCOUNT ON;
        BEGIN TRY
            BEGIN TRANSACTION;

            -- Cập nhật bảng Instance
            UPDATE dbo.tblWF_Instance
            SET StepDueDate = @StepDueDate,
                StepStartDate = @StepStartDate,
                UpdateTime = GETDATE(),
                UpdateUser = @sys_UserID
            WHERE InstanceID = @InstanceID
              AND [Enable] = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
                SELECT 0 AS Success, N'Không tìm thấy hồ sơ hoặc hồ sơ đã bị xóa' AS Message;
                RETURN;
            END

            COMMIT TRANSACTION;
            SELECT 1 AS Success, N'Cập nhật thời hạn hết hạn thành công' AS Message;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            SELECT 0 AS Success, ERROR_MESSAGE() AS Message;
        END CATCH
    END
    