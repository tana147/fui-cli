CREATE PROCEDURE [dbo].[spAPI_WF_Audit_BulkUpdateStatus]
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TargetType VARCHAR(30) = LOWER(ISNULL(JSON_VALUE(@sys_RawData, '$.TargetType'), ''));
    DECLARE @NewStatus VARCHAR(30) = JSON_VALUE(@sys_RawData, '$.NewStatus');

    IF ISNULL(@TargetType, '') = '' OR ISNULL(@NewStatus, '') = ''
    BEGIN
        RAISERROR(N'Thiếu TargetType hoặc NewStatus.', 16, 1);
        RETURN;
    END

    DECLARE @IDs TABLE (ID BIGINT NOT NULL);
    INSERT INTO @IDs (ID)
    SELECT TRY_CAST([value] AS BIGINT)
    FROM OPENJSON(@sys_RawData, '$.IDList')
    WHERE TRY_CAST([value] AS BIGINT) IS NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM @IDs)
    BEGIN
        RAISERROR(N'Không có dòng nào được chọn để cập nhật.', 16, 1);
        RETURN;
    END

    IF @TargetType = 'checklist'
    BEGIN
        UPDATE T
        SET Status = @NewStatus,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        FROM dbo.tblWF_AuditChecklist AS T
        INNER JOIN @IDs AS I ON I.ID = T.ChecklistID
        WHERE T.[Enable] = 0;
    END
    ELSE IF @TargetType = 'testcase'
    BEGIN
        UPDATE T
        SET Status = @NewStatus,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        FROM dbo.tblWF_AuditTestCase AS T
        INNER JOIN @IDs AS I ON I.ID = T.AuditTestCaseID
        WHERE T.[Enable] = 0;
    END
    ELSE IF @TargetType = 'backlog'
    BEGIN
        UPDATE T
        SET Status = @NewStatus,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        FROM dbo.tblWF_AuditBacklog AS T
        INNER JOIN @IDs AS I ON I.ID = T.BacklogID
        WHERE T.[Enable] = 0;
    END
    ELSE IF @TargetType = 'spec'
    BEGIN
        UPDATE T
        SET Status = @NewStatus,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        FROM dbo.tblWF_AuditSpecChange AS T
        INNER JOIN @IDs AS I ON I.ID = T.SpecChangeID
        WHERE T.[Enable] = 0;
    END
    ELSE
    BEGIN
        RAISERROR(N'TargetType không hợp lệ.', 16, 1);
        RETURN;
    END

    SELECT Message = N'Cập nhật trạng thái hàng loạt thành công.',
           TargetType = @TargetType,
           NewStatus = @NewStatus,
           UpdatedCount = (SELECT COUNT(1) FROM @IDs);
END
