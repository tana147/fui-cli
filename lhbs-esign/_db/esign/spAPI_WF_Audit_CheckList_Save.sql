CREATE PROCEDURE [dbo].[spAPI_WF_Audit_CheckList_Save]
    @ChecklistID BIGINT = 0,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ModuleKey VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.ModuleKey');
    DECLARE @ItemGroup NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.ItemGroup');
    DECLARE @ItemTitle NVARCHAR(300) = JSON_VALUE(@sys_RawData, '$.ItemTitle');
    DECLARE @Status VARCHAR(30) = ISNULL(JSON_VALUE(@sys_RawData, '$.Status'), 'TODO');
    DECLARE @Priority VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.Priority');
    DECLARE @PICType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.PICType');
    DECLARE @PICCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.PICCode');
    DECLARE @PICName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.PICName');
    DECLARE @HandlerType VARCHAR(20) = JSON_VALUE(@sys_RawData, '$.HandlerType');
    DECLARE @HandlerCode VARCHAR(100) = JSON_VALUE(@sys_RawData, '$.HandlerCode');
    DECLARE @HandlerName NVARCHAR(200) = JSON_VALUE(@sys_RawData, '$.HandlerName');
    DECLARE @Note NVARCHAR(1000) = JSON_VALUE(@sys_RawData, '$.Note');

    IF ISNULL(@ItemTitle, '') = ''
    BEGIN
        RAISERROR(N'Tiêu đề checklist không được để trống.', 16, 1);
        RETURN;
    END

    IF @ChecklistID = 0
    BEGIN
        INSERT INTO dbo.tblWF_AuditChecklist (ModuleKey, ItemGroup, ItemTitle, Status, Priority, PICType, PICCode, PICName, HandlerType, HandlerCode, HandlerName, Note, CreateUser, CreateTime, [Enable])
        VALUES (@ModuleKey, @ItemGroup, @ItemTitle, @Status, @Priority, @PICType, @PICCode, @PICName, @HandlerType, @HandlerCode, @HandlerName, @Note, @sys_UserID, GETDATE(), 0);
        SET @ChecklistID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        UPDATE dbo.tblWF_AuditChecklist
        SET ModuleKey = @ModuleKey, ItemGroup = @ItemGroup, ItemTitle = @ItemTitle, Status = @Status, Priority = @Priority,
            PICType = @PICType, PICCode = @PICCode, PICName = @PICName,
            HandlerType = @HandlerType, HandlerCode = @HandlerCode, HandlerName = @HandlerName,
            Note = @Note, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
        WHERE ChecklistID = @ChecklistID AND [Enable] = 0;
    END

    SELECT Message = N'Lưu checklist thành công.', ChecklistID = @ChecklistID;
END
