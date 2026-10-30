CREATE PROCEDURE [dbo].[spAPI_WF_Instance_Delete]
    @sys_UserID VARCHAR(9),
    @InstanceID BIGINT
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

        -- 1. Soft delete Instance
        UPDATE dbo.tblWF_Instance
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID;

        -- 2. Soft delete related data
        UPDATE dbo.tblWF_StepExecution
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID;

        UPDATE dbo.tblWF_InstanceChecklist
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID;

        UPDATE dbo.tblWF_InstanceData
        SET [Enable] = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID;

        UPDATE dbo.tblWF_InstanceTask
        SET Enable = 0,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID;

        -- 🟢 [MỚI] Tự động xoá mềm các bản ghi thực thi gán quyền trong bảng tblWF_StepAssigneeExec tương ứng
        UPDATE AE
        SET AE.[Enable] = 0,
            AE.UpdateUser = @sys_UserID,
            AE.UpdateTime = GETDATE()
        FROM dbo.tblWF_StepAssigneeExec AS AE
        INNER JOIN dbo.tblWF_StepExecution AS EX ON EX.ExecutionID = AE.ExecutionID
        WHERE EX.InstanceID = @InstanceID;

        COMMIT TRANSACTION;

        SELECT 1 AS Success, N'Xóa luồng công việc thành công.' AS Message, @InstanceID AS InstanceID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END
