CREATE PROCEDURE [dbo].[spAPI_WF_InstanceChecklist_Save]
    @InstanceID BIGINT,
    @ChecklistDefID BIGINT,
    @sys_UserID VARCHAR(9),
    @DataJSON NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @IsCompleted BIT = ISNULL(CAST(JSON_VALUE(@DataJSON, '$.IsCompleted') AS BIT), 0);
    DECLARE @SubmitMethod VARCHAR(20) = JSON_VALUE(@DataJSON, '$.SubmitMethod');
    DECLARE @AttachmentUrl NVARCHAR(500) = JSON_VALUE(@DataJSON, '$.AttachmentUrl');
    DECLARE @IsDeferred BIT = ISNULL(CAST(JSON_VALUE(@DataJSON, '$.IsDeferred') AS BIT), 0);
    DECLARE @DeferredDueDate DATE = NULL;
    DECLARE @Note NVARCHAR(500) = JSON_VALUE(@DataJSON, '$.Note');

    IF JSON_VALUE(@DataJSON, '$.DeferredDueDate') IS NOT NULL AND JSON_VALUE(@DataJSON, '$.DeferredDueDate') <> ''
    BEGIN
        SET @DeferredDueDate = CAST(JSON_VALUE(@DataJSON, '$.DeferredDueDate') AS DATE);
    END

    -- Cap nhat hoac Them moi trang thai
    IF EXISTS (SELECT 1 FROM dbo.tblWF_InstanceChecklist WHERE InstanceID = @InstanceID AND ChecklistDefID = @ChecklistDefID AND [Enable] = 1)
    BEGIN
        UPDATE dbo.tblWF_InstanceChecklist
        SET IsCompleted = @IsCompleted,
            SubmitMethod = @SubmitMethod,
            AttachmentUrl = @AttachmentUrl,
            IsDeferred = @IsDeferred,
            DeferredDueDate = @DeferredDueDate,
            Note = @Note,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE InstanceID = @InstanceID AND ChecklistDefID = @ChecklistDefID AND [Enable] = 1;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblWF_InstanceChecklist (
            InstanceID, ChecklistDefID, IsCompleted, SubmitMethod, AttachmentUrl, IsDeferred, DeferredDueDate, Note, CreateUser, CreateTime, [Enable]
        )
        VALUES (
            @InstanceID, @ChecklistDefID, @IsCompleted, @SubmitMethod, @AttachmentUrl, @IsDeferred, @DeferredDueDate, @Note, @sys_UserID, GETDATE(), 1
        );
    END

    SELECT Message = N'Lưu trạng thái checklist ứng viên thành công.', InstanceID = @InstanceID, ChecklistDefID = @ChecklistDefID;
END

