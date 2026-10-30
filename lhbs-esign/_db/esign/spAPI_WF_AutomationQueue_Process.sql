CREATE PROCEDURE [dbo].[spAPI_WF_AutomationQueue_Process]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @QueueID BIGINT;
    DECLARE @InstanceID BIGINT;
    DECLARE @RuleName NVARCHAR(200);
    DECLARE @ActionType VARCHAR(50);
    DECLARE @ActionParamsJSON NVARCHAR(MAX);
    DECLARE @CreateUser VARCHAR(50);

    -- 1. Fetch pending queued records
    DECLARE queue_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT QueueID, InstanceID, RuleName, ActionType, ActionParamsJSON, CreateUser
        FROM dbo.tblWF_AutomationQueue
        WHERE Status = 'QUEUED'
        ORDER BY CreateTime ASC;

    OPEN queue_cur
    FETCH NEXT FROM queue_cur INTO @QueueID, @InstanceID, @RuleName, @ActionType, @ActionParamsJSON, @CreateUser

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Update status to PROCESSING to prevent duplicate picking if multiple processors run
            UPDATE dbo.tblWF_AutomationQueue
            SET Status = 'PROCESSING'
            WHERE QueueID = @QueueID;

            -- Initialize status tracking
            DECLARE @FinalStatus VARCHAR(20) = 'COMPLETED';
            DECLARE @ErrorMessage NVARCHAR(MAX) = NULL;

            -- ── ACTION: CROSS_WF_CREATE ──────────────────────────────────────────────
            IF @ActionType = 'CROSS_WF_CREATE'
            BEGIN
                DECLARE @TargetWF BIGINT = TRY_CAST(JSON_VALUE(@ActionParamsJSON, '$.TargetWF') AS BIGINT);
                DECLARE @SourceInstanceName NVARCHAR(200);
                DECLARE @SourceReferenceCode VARCHAR(50);
                DECLARE @SourceFileID UNIQUEIDENTIFIER;
                DECLARE @SourceFileName NVARCHAR(255);

                IF ISNULL(@TargetWF, 0) <= 0
                    THROW 50000, N'Thiếu TargetWF hoặc TargetWF không hợp lệ.', 1;

                -- Get basic info and attachment from source instance
                SELECT 
                    @SourceInstanceName = InstanceName, 
                    @SourceReferenceCode = ReferenceCode,
                    @SourceFileID = SourceFileID,
                    @SourceFileName = SourceFileName
                FROM dbo.tblWF_Instance 
                WHERE InstanceID = @InstanceID;

                -- Construct payload for spAPI_WF_Request_Create
                DECLARE @TargetTemplateID BIGINT = (SELECT TOP 1 TemplateID FROM dbo.tblWF_StepDefinition WHERE DefinitionID = @TargetWF AND TemplateID IS NOT NULL AND TemplateID > 0 AND [Enable] = 1 ORDER BY StepOrder);
                DECLARE @CreateMode VARCHAR(20) = CASE WHEN @TargetTemplateID > 0 THEN 'TEMPLATE_FLOW' ELSE 'FREE_SIGN' END;
                
                DECLARE @RawData NVARCHAR(MAX) = (
                    SELECT 
                        @CreateMode AS CreateMode,
                        @TargetWF AS DefinitionID,
                        @TargetTemplateID AS TemplateID,
                        -- Tự động thêm tiền tố để dễ phân biệt
                        N'[Tự động] ' + ISNULL(@SourceInstanceName, N'Công việc mới') AS InstanceName,
                        @SourceReferenceCode AS ReferenceCode,
                        N'Được tạo tự động từ quy tắc: ' + @RuleName AS [Description],
                        @SourceFileID AS FileID,
                        @SourceFileName AS UploadFileName,
                        CASE WHEN @SourceFileID IS NOT NULL THEN 'UPLOAD' ELSE 'TEMPLATE' END AS FileMethod
                    FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                );

                -- Call create request SP
                -- This creates the instance synchronously
                DECLARE @DummyResult TABLE (
                    Message NVARCHAR(500),
                    InstanceID BIGINT,
                    InstanceName NVARCHAR(200),
                    Status VARCHAR(20),
                    CurrentStepOrder INT,
                    CreateMode VARCHAR(20)
                );

                INSERT INTO @DummyResult
                EXEC dbo.spAPI_WF_Request_Create 
                    @DefinitionID = @TargetWF, 
                    @sys_UserID = @CreateUser, 
                    @sys_RawData = @RawData;
            END

            -- ── ACTION: SEND_EMAIL ───────────────────────────────────────────────────
            ELSE IF @ActionType = 'SEND_EMAIL'
            BEGIN
                -- TODO: Implement email sending logic here or call email queue SP
                SET @FinalStatus = 'COMPLETED';
            END

            ELSE
            BEGIN
                -- Unknown Action Type
                SET @FinalStatus = 'FAILED';
                SET @ErrorMessage = N'ActionType không được hỗ trợ: ' + @ActionType;
            END

            -- Update Final Status
            UPDATE dbo.tblWF_AutomationQueue
            SET Status = @FinalStatus, 
                ErrorMessage = @ErrorMessage
            WHERE QueueID = @QueueID;

        END TRY
        BEGIN CATCH
            -- Handle Errors
            UPDATE dbo.tblWF_AutomationQueue
            SET Status = 'FAILED', 
                ErrorMessage = ERROR_MESSAGE()
            WHERE QueueID = @QueueID;
        END CATCH

        FETCH NEXT FROM queue_cur INTO @QueueID, @InstanceID, @RuleName, @ActionType, @ActionParamsJSON, @CreateUser
    END

    CLOSE queue_cur
    DEALLOCATE queue_cur

END
