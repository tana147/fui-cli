
CREATE PROCEDURE [dbo].[spAPI_WF_Automation_Execute]
    @sys_UserID   VARCHAR(9),
    @InstanceID   BIGINT,
    @Event        VARCHAR(50),
    @InternalCall BIT = 0
AS
BEGIN
    -- INJECTED DEBUG LOG
--    INSERT INTO dbo.tblDebugLog (Message)
--    VALUES (N'START EXEC spAPI_WF_Automation_Execute - User: ' + ISNULL(@sys_UserID, 'NULL') 
--            + N', InstanceID: ' + CAST(@InstanceID AS VARCHAR(10)) 
--            + N', Event: ' + ISNULL(@Event, 'NULL')
--            + N', InternalCall: ' + CAST(@InternalCall AS VARCHAR(2)));

    BEGIN TRY
    
    SET NOCOUNT ON

    -- ── Declarations ──────────────────────────────────────────────────────────
    DECLARE @DefinitionID        BIGINT
    DECLARE @CurrentStepOrder    INT
    DECLARE @CurrentStepDefID    BIGINT
    DECLARE @ConditionJSON       NVARCHAR(MAX)
    DECLARE @AutomationRulesJSON NVARCHAR(MAX)

    -- Rule iteration
    DECLARE @RuleJSON            NVARCHAR(MAX)
    DECLARE @RuleName            NVARCHAR(200)
    DECLARE @ActionType          VARCHAR(50)
    DECLARE @ActionParamsJSON    NVARCHAR(MAX)
    DECLARE @ConditionGroupJSON  NVARCHAR(MAX)
    DECLARE @CGLogic             VARCHAR(10)
    DECLARE @ItemsJSON           NVARCHAR(MAX)
    DECLARE @ConditionPassed     BIT

    -- Shared action variables (reset between rules)
    DECLARE @StepDefID  BIGINT
    DECLARE @StepOrder  INT
    DECLARE @StepName   NVARCHAR(200)
    DECLARE @ExecID     BIGINT
    DECLARE @FieldName  VARCHAR(100)
    DECLARE @FieldValue NVARCHAR(500)
    DECLARE @AssignTo   NVARCHAR(100)
    DECLARE @TargetStepType VARCHAR(20)

    -- Condition evaluation results per rule
    DECLARE @CondResults TABLE (Passed BIT)

    -- ── 1. Load instance ──────────────────────────────────────────────────────
    SELECT @DefinitionID = DefinitionID, @CurrentStepOrder = CurrentStepOrder
    FROM dbo.tblWF_Instance
    WHERE InstanceID = @InstanceID AND [Enable] = 1

--    INSERT INTO dbo.tblDebugLog (Message) VALUES (
--        N'[DBG] InstanceID=' + CAST(@InstanceID AS NVARCHAR(10))
--        + N' | DefinitionID=' + ISNULL(CAST(@DefinitionID AS NVARCHAR(10)), N'NULL')
--        + N' | CurrentStepOrder=' + ISNULL(CAST(@CurrentStepOrder AS NVARCHAR(10)), N'NULL')
--    )

    IF @DefinitionID IS NULL
    BEGIN
        INSERT INTO dbo.tblDebugLog (Message) VALUES (N'[DBG] EARLY RETURN: DefinitionID IS NULL for InstanceID=' + CAST(@InstanceID AS NVARCHAR(10)))
        IF @InternalCall = 0
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy hồ sơ' AS Message,
               NULL AS ActionType, NULL AS NewStepDefID
        RETURN
    END

    -- ── 2. Load current step definition + ConditionJSON ───────────────────────
    SELECT TOP 1 @CurrentStepDefID = StepDefID, @ConditionJSON = ConditionJSON
    FROM dbo.tblWF_StepDefinition
    WHERE DefinitionID = @DefinitionID AND StepOrder = @CurrentStepOrder AND [Enable] = 1

    SET @AutomationRulesJSON = JSON_QUERY(@ConditionJSON, '$.AutomationRules')

    INSERT INTO dbo.tblDebugLog (Message) VALUES (
        N'[DBG] StepDefID=' + ISNULL(CAST(@CurrentStepDefID AS NVARCHAR(10)), N'NULL')
        + N' | AutomationRulesJSON=' + CASE WHEN @AutomationRulesJSON IS NULL THEN N'NULL' ELSE LEFT(@AutomationRulesJSON, 100) END
    )

    IF @AutomationRulesJSON IS NULL OR LEN(ISNULL(@AutomationRulesJSON, '')) <= 2
    BEGIN
        INSERT INTO dbo.tblDebugLog (Message) VALUES (N'[DBG] EARLY RETURN: AutomationRulesJSON NULL/empty for StepDefID=' + ISNULL(CAST(@CurrentStepDefID AS NVARCHAR(10)), N'NULL'))
        IF @InternalCall = 0
        SELECT CAST(1 AS BIT) AS Success, N'Không có quy tắc tự động hóa' AS Message,
               NULL AS ActionType, NULL AS NewStepDefID
        RETURN
    END

    -- ── 3. Field values for condition evaluation ──────────────────────────────
    CREATE TABLE #FieldValues (FieldName NVARCHAR(255), FieldValue NVARCHAR(500))
    INSERT INTO #FieldValues (FieldName, FieldValue)
    SELECT FieldName, ISNULL(FieldValue, '')
    FROM dbo.tblWF_InstanceData
    WHERE InstanceID = @InstanceID AND [Enable] = 1

    -- ── 3.1. Subtask variables for condition evaluation ───────────────────────
    DECLARE @TotalTasks INT = 0
    DECLARE @CompletedTasks INT = 0
    DECLARE @TotalRequiredTasks INT = 0
    DECLARE @CompletedRequiredTasks INT = 0

    SELECT 
        @TotalTasks = COUNT(1),
        @CompletedTasks = SUM(CASE WHEN Status = 'DONE' THEN 1 ELSE 0 END),
        @TotalRequiredTasks = SUM(CASE WHEN IsRequired = 1 THEN 1 ELSE 0 END),
        @CompletedRequiredTasks = SUM(CASE WHEN IsRequired = 1 AND Status = 'DONE' THEN 1 ELSE 0 END)
    FROM dbo.tblWF_InstanceTask
    WHERE InstanceID = @InstanceID 
      AND StepDefID = @CurrentStepDefID 
      AND [Enable] = 1

    INSERT INTO #FieldValues (FieldName, FieldValue)
    VALUES 
        ('sys_TotalTasks', CAST(ISNULL(@TotalTasks, 0) AS VARCHAR(10))),
        ('sys_CompletedTasks', CAST(ISNULL(@CompletedTasks, 0) AS VARCHAR(10))),
        ('sys_PendingTasks', CAST(ISNULL(@TotalTasks - @CompletedTasks, 0) AS VARCHAR(10))),
        ('sys_TotalRequiredTasks', CAST(ISNULL(@TotalRequiredTasks, 0) AS VARCHAR(10))),
        ('sys_CompletedRequiredTasks', CAST(ISNULL(@CompletedRequiredTasks, 0) AS VARCHAR(10))),
        ('sys_PendingRequiredTasks', CAST(ISNULL(@TotalRequiredTasks - @CompletedRequiredTasks, 0) AS VARCHAR(10)))

    -- Đưa trạng thái từng việc con cụ thể vào dưới dạng task_tên_nhiệm_vụ = 'DONE' hoặc 'TODO'
    INSERT INTO #FieldValues (FieldName, FieldValue)
    SELECT 
        'task_' + LOWER(REPLACE(REPLACE(TaskName, ' ', '_'), '-', '_')),
        Status
    FROM dbo.tblWF_InstanceTask
    WHERE InstanceID = @InstanceID 
      AND StepDefID = @CurrentStepDefID 
      AND [Enable] = 1

    -- ── 4. Results accumulator ────────────────────────────────────────────────
    CREATE TABLE #Results (
        ActionType   VARCHAR(50),
        Success      BIT,
        Message      NVARCHAR(500),
        NewStepDefID BIGINT NULL
    )

    -- ── 5. Iterate rules matching the event ───────────────────────────────────
    DECLARE rule_cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT [value]
        FROM OPENJSON(@AutomationRulesJSON)
        WHERE JSON_VALUE([value], '$.Event') = @Event
           OR (@Event IN ('TASK_CREATED', 'SUBTASK_DONE') AND JSON_VALUE([value], '$.Event') = 'STAGE_CHANGED')

    OPEN rule_cur
    FETCH NEXT FROM rule_cur INTO @RuleJSON

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @RuleName           = JSON_VALUE(@RuleJSON, '$.RuleName')
        SET @ActionType         = JSON_VALUE(@RuleJSON, '$.Action.Type')
        SET @ActionParamsJSON   = JSON_QUERY(@RuleJSON, '$.Action.Params')
        SET @ConditionGroupJSON = JSON_QUERY(@RuleJSON, '$.ConditionGroup')
        SET @CGLogic            = ISNULL(JSON_VALUE(@ConditionGroupJSON, '$.Logic'), 'AND')
        SET @ConditionPassed    = 1  -- default: no conditions = always pass

        -- ── Evaluate ConditionGroup ──────────────────────────────────────────
        DELETE FROM @CondResults
        SET @ItemsJSON = JSON_QUERY(@ConditionGroupJSON, '$.Items')

        IF @ItemsJSON IS NOT NULL AND LEN(@ItemsJSON) > 2
        BEGIN
            INSERT INTO @CondResults (Passed)
            SELECT
                CASE
                    -- Sub-group (item has "Logic" key)
                    WHEN JSON_VALUE(item.[value], '$.Logic') IS NOT NULL THEN
                        CASE ISNULL(JSON_VALUE(item.[value], '$.Logic'), 'AND')
                            WHEN 'OR' THEN
                                CASE WHEN EXISTS (
                                    SELECT 1 FROM OPENJSON(JSON_QUERY(item.[value], '$.Items')) sub
                                    LEFT JOIN #FieldValues fv ON fv.FieldName = JSON_VALUE(sub.[value], '$.FieldName')
                                    WHERE dbo.fnWF_EvalCondition(
                                        ISNULL(fv.FieldValue, ''),
                                        JSON_VALUE(sub.[value], '$.Operator'),
                                        ISNULL(JSON_VALUE(sub.[value], '$.Value'), '')
                                    ) = 1
                                ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
                            ELSE  -- AND
                                CASE WHEN NOT EXISTS (
                                    SELECT 1 FROM OPENJSON(JSON_QUERY(item.[value], '$.Items')) sub
                                    LEFT JOIN #FieldValues fv ON fv.FieldName = JSON_VALUE(sub.[value], '$.FieldName')
                                    WHERE dbo.fnWF_EvalCondition(
                                        ISNULL(fv.FieldValue, ''),
                                        JSON_VALUE(sub.[value], '$.Operator'),
                                        ISNULL(JSON_VALUE(sub.[value], '$.Value'), '')
                                    ) = 0
                                ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
                        END
                    -- Simple condition
                    ELSE
                        dbo.fnWF_EvalCondition(
                            ISNULL((SELECT TOP 1 FieldValue FROM #FieldValues WHERE FieldName = JSON_VALUE(item.[value], '$.FieldName')), ''),
                            JSON_VALUE(item.[value], '$.Operator'),
                            ISNULL(JSON_VALUE(item.[value], '$.Value'), '')
                        )
                END
            FROM OPENJSON(@ItemsJSON) item

            -- Aggregate: AND = all pass, OR = any pass
            IF EXISTS(SELECT 1 FROM @CondResults)
                SELECT @ConditionPassed = CASE @CGLogic
                    WHEN 'OR' THEN CASE WHEN MAX(CAST(Passed AS INT)) = 1 THEN 1 ELSE 0 END
                    ELSE            CASE WHEN MIN(CAST(Passed AS INT)) = 1 THEN 1 ELSE 0 END
                END
                FROM @CondResults
        END

        INSERT INTO dbo.tblDebugLog (Message) VALUES (
            N'[DBG] Rule=' + ISNULL(@RuleName, N'NULL')
            + N' | ActionType=' + ISNULL(@ActionType, N'NULL')
            + N' | ConditionPassed=' + CAST(@ConditionPassed AS NVARCHAR(1))
        )

        -- ── Execute action if conditions passed ──────────────────────────────
        IF @ConditionPassed = 1
        BEGIN

            -- ── AUTO_COMPLETE: move to next step ──────────────────────────────
            IF @ActionType = 'AUTO_COMPLETE'
            BEGIN
                SET @StepDefID = NULL; SET @StepOrder = NULL; SET @StepName = NULL

                SELECT TOP 1 @StepDefID = StepDefID, @StepOrder = StepOrder, @StepName = StepName, @TargetStepType = StepType
                FROM dbo.tblWF_StepDefinition
                WHERE DefinitionID = @DefinitionID AND StepOrder > @CurrentStepOrder AND [Enable] = 1
                ORDER BY StepOrder ASC

                IF @StepDefID IS NOT NULL
                BEGIN
                    BEGIN TRY
                        BEGIN TRANSACTION
                        UPDATE dbo.tblWF_Instance
                        SET CurrentStepOrder = @StepOrder, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                        WHERE InstanceID = @InstanceID

                        UPDATE dbo.tblWF_StepExecution
                        SET Status = 'COMPLETED', CompletedDate = GETDATE(),
                            UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                        WHERE InstanceID = @InstanceID AND Status = 'ACTIVE'

                        INSERT INTO dbo.tblWF_StepExecution
                            (InstanceID, StepDefID, StepName, StepOrder, Status, StartedDate, [Enable], CreateTime, CreateUser)
                        VALUES (@InstanceID, @StepDefID, @StepName, @StepOrder, 'ACTIVE', GETDATE(), 1, GETDATE(), @sys_UserID)

                        SET @ExecID = SCOPE_IDENTITY()
                        INSERT INTO dbo.tblWF_InstanceTask
                            (ExecutionID, InstanceID, StepDefID, TaskName, Description, DueHours, Status, [Enable], CreateTime, CreateUser, SortOrder)
                        SELECT @ExecID, @InstanceID, @StepDefID,
                               TaskName, Description, ISNULL(DueHours, 24), 'TODO', 1, GETDATE(), @sys_UserID, SortOrder
                        FROM dbo.tblWF_Task
                        WHERE StepDefID = @StepDefID AND [Enable] = 1

                        -- ── Handle Terminal Steps (SUCCESS/FAILURE) ──
                        IF @TargetStepType IN ('SUCCESS', 'FAILURE')
                        BEGIN
                            UPDATE dbo.tblWF_Instance
                            SET Status = CASE WHEN @TargetStepType = 'SUCCESS' THEN 'COMPLETED' ELSE 'FAILED' END,
                                UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                            WHERE InstanceID = @InstanceID

                            UPDATE dbo.tblWF_StepExecution
                            SET Status = 'COMPLETED', CompletedDate = GETDATE(),
                                UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                            WHERE ExecutionID = @ExecID
                        END

                        COMMIT TRANSACTION
                        INSERT INTO #Results VALUES ('AUTO_COMPLETE', 1, N'Tự động chuyển sang bước: ' + @StepName, @StepDefID)
                    END TRY
                    BEGIN CATCH
                        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
                        INSERT INTO #Results VALUES ('AUTO_COMPLETE', 0, N'Lỗi AUTO_COMPLETE: ' + ERROR_MESSAGE(), NULL)
                    END CATCH
                END
                ELSE
                BEGIN
                    -- No next step → mark instance COMPLETED
                    UPDATE dbo.tblWF_Instance
                    SET Status = 'COMPLETED', UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                    WHERE InstanceID = @InstanceID

                    UPDATE dbo.tblWF_StepExecution
                    SET Status = 'COMPLETED', CompletedDate = GETDATE(),
                        UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                    WHERE InstanceID = @InstanceID AND Status = 'ACTIVE'

                    INSERT INTO #Results VALUES ('AUTO_COMPLETE', 1, N'Hồ sơ đã hoàn thành toàn bộ quy trình', NULL)
                END
            END

            -- ── JUMP_TO / SKIP_STEP: move to target/next step ─────────────────
            ELSE IF @ActionType IN ('JUMP_TO', 'SKIP_STEP')
            BEGIN
                SET @StepDefID = NULL; SET @StepOrder = NULL; SET @StepName = NULL

                IF @ActionType = 'JUMP_TO'
                BEGIN
                    -- UI lưu TargetStep dưới dạng số thứ tự bước (StepOrder), cần tìm StepDefID tương ứng của Definition hiện tại
                    DECLARE @JumpStepOrder INT = TRY_CAST(JSON_VALUE(@ActionParamsJSON, '$.TargetStep') AS INT)
                    SELECT TOP 1 @StepDefID = StepDefID
                    FROM dbo.tblWF_StepDefinition
                    WHERE DefinitionID = @DefinitionID AND StepOrder = @JumpStepOrder AND [Enable] = 1
                END
                ELSE
                BEGIN
                    SELECT TOP 1 @StepDefID = StepDefID
                    FROM dbo.tblWF_StepDefinition
                    WHERE DefinitionID = @DefinitionID AND StepOrder > @CurrentStepOrder AND [Enable] = 1
                    ORDER BY StepOrder ASC
                END

                SELECT @StepOrder = StepOrder, @StepName = StepName, @TargetStepType = StepType
                FROM dbo.tblWF_StepDefinition
                WHERE StepDefID = @StepDefID AND [Enable] = 1

                IF @StepOrder IS NOT NULL
                BEGIN
                    BEGIN TRY
                        BEGIN TRANSACTION
                        UPDATE dbo.tblWF_Instance
                        SET CurrentStepOrder = @StepOrder, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                        WHERE InstanceID = @InstanceID

                        UPDATE dbo.tblWF_StepExecution
                        SET Status = 'COMPLETED', CompletedDate = GETDATE(),
                            UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                        WHERE InstanceID = @InstanceID AND Status = 'ACTIVE'

                        INSERT INTO dbo.tblWF_StepExecution
                            (InstanceID, StepDefID, StepName, StepOrder, Status, StartedDate, [Enable], CreateTime, CreateUser)
                        VALUES (@InstanceID, @StepDefID, @StepName, @StepOrder, 'ACTIVE', GETDATE(), 1, GETDATE(), @sys_UserID)

                        SET @ExecID = SCOPE_IDENTITY()
                        INSERT INTO dbo.tblWF_InstanceTask
                            (ExecutionID, InstanceID, StepDefID, TaskName, Description, DueHours, Status, [Enable], CreateTime, CreateUser, SortOrder)
                        SELECT @ExecID, @InstanceID, @StepDefID,
                               TaskName, Description, ISNULL(DueHours, 24), 'TODO', 1, GETDATE(), @sys_UserID, SortOrder
                        FROM dbo.tblWF_Task
                        WHERE StepDefID = @StepDefID AND [Enable] = 1

                        -- ── Handle Terminal Steps (SUCCESS/FAILURE) ──
                        IF @TargetStepType IN ('SUCCESS', 'FAILURE')
                        BEGIN
                            UPDATE dbo.tblWF_Instance
                            SET Status = CASE WHEN @TargetStepType = 'SUCCESS' THEN 'COMPLETED' ELSE 'FAILED' END,
                                UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                            WHERE InstanceID = @InstanceID

                            UPDATE dbo.tblWF_StepExecution
                            SET Status = 'COMPLETED', CompletedDate = GETDATE(),
                                UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                            WHERE ExecutionID = @ExecID
                        END

                        COMMIT TRANSACTION
                        INSERT INTO #Results VALUES (@ActionType, 1, N'Đã chuyển sang bước: ' + @StepName, @StepDefID)
                    END TRY
                    BEGIN CATCH
                        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
                        INSERT INTO #Results VALUES (@ActionType, 0, N'Lỗi ' + @ActionType + ': ' + ERROR_MESSAGE(), NULL)
                    END CATCH
                END
            END

            -- ── UPDATE_FIELD: cập nhật trường dữ liệu ────────────────────────
            ELSE IF @ActionType = 'UPDATE_FIELD'
            BEGIN
                SET @FieldName  = JSON_VALUE(@ActionParamsJSON, '$.FieldName')
                SET @FieldValue = JSON_VALUE(@ActionParamsJSON, '$.FieldValue')

                IF @FieldName IS NOT NULL
                BEGIN
                    BEGIN TRY
                        IF EXISTS(SELECT 1 FROM dbo.tblWF_InstanceData WHERE InstanceID = @InstanceID AND FieldName = @FieldName AND [Enable] = 1)
                            UPDATE dbo.tblWF_InstanceData
                            SET FieldValue = @FieldValue, UpdateTime = GETDATE(), UpdateUser = @sys_UserID
                            WHERE InstanceID = @InstanceID AND FieldName = @FieldName AND [Enable] = 1
                        ELSE
                            INSERT INTO dbo.tblWF_InstanceData (InstanceID, FieldName, FieldValue, [Enable], CreateTime, CreateUser)
                            VALUES (@InstanceID, @FieldName, @FieldValue, 1, GETDATE(), @sys_UserID)

                        INSERT INTO #Results VALUES ('UPDATE_FIELD', 1, N'Đã cập nhật trường: ' + @FieldName, NULL)
                    END TRY
                    BEGIN CATCH
                        INSERT INTO #Results VALUES ('UPDATE_FIELD', 0, N'Lỗi UPDATE_FIELD: ' + ERROR_MESSAGE(), NULL)
                    END CATCH
                END
            END

            -- ── ASSIGN_PIC: gán người phụ trách ─────────────────────────────
            ELSE IF @ActionType = 'ASSIGN_PIC'
            BEGIN
                SET @AssignTo = JSON_VALUE(@ActionParamsJSON, '$.AssignTo')

                IF @AssignTo IS NOT NULL
                BEGIN
                    BEGIN TRY
                        -- Resolve UserID và FullName của người được gán tự động
                        DECLARE @ResolvedUserID BIGINT = NULL;
                        DECLARE @ResolvedName NVARCHAR(200) = NULL;
                        SELECT TOP 1 
                            @ResolvedUserID = UserID,
                            @ResolvedName = ISNULL(NULLIF(LTRIM(RTRIM(FullName)), N''), NULL)
                        FROM dbo.tblWF_User
                        WHERE [Enable] = 1
                          AND ISNULL(IsActive, 1) = 1
                          AND (
                              UPPER(ISNULL(EmployeeCode, '')) = UPPER(ISNULL(@AssignTo, ''))
                              OR UPPER(ISNULL(Email, ''))     = UPPER(ISNULL(@AssignTo, ''))
                          )
                        ORDER BY
                            CASE WHEN UPPER(ISNULL(EmployeeCode,'')) = UPPER(ISNULL(@AssignTo,'')) THEN 0 ELSE 1 END,
                            UserID DESC;

                        -- 1. Cập nhật người phụ trách cho signer WAITING của execution hiện tại
                        UPDATE se
                        SET se.ResolvedPersonID   = @AssignTo,
                            se.ResolvedPersonName = ISNULL(@ResolvedName, se.ResolvedPersonName),
                            se.UpdateTime         = GETDATE(),
                            se.UpdateUser         = @sys_UserID
                        FROM dbo.tblWF_StepSignerExec se
                        INNER JOIN dbo.tblWF_StepExecution ex ON ex.ExecutionID = se.ExecutionID
                        WHERE ex.InstanceID = @InstanceID
                          AND ex.Status     = 'ACTIVE'
                          AND ex.Enable     = 1
                          AND se.Status     = 'WAITING'
                          AND se.Enable     = 1

                        -- 2. Cập nhật đồng bộ cho bảng thực thi gán quyền mới tblWF_StepAssigneeExec
                        UPDATE ae
                        SET ae.EmployeeID   = ISNULL(@ResolvedUserID, ae.EmployeeID),
                            ae.EmployeeCode = @AssignTo,
                            ae.FullName     = ISNULL(@ResolvedName, ae.FullName),
                            ae.UpdateTime   = GETDATE(),
                            ae.UpdateUser   = @sys_UserID
                        FROM dbo.tblWF_StepAssigneeExec ae
                        INNER JOIN dbo.tblWF_StepExecution ex ON ex.ExecutionID = ae.ExecutionID
                        WHERE ex.InstanceID = @InstanceID
                          AND ex.Status     = 'ACTIVE'
                          AND ex.Enable     = 1
                          AND ae.Enable     = 1
                          
                       -- 3. Cập nhật trực tiếp người phụ trách chính cho Instance để hiển thị trên UI Kanban
                        UPDATE dbo.tblWF_Instance
                        SET AssigneeCode = @AssignTo,
                            UpdateTime   = GETDATE(),
                            UpdateUser   = @sys_UserID
                        WHERE InstanceID = @InstanceID

                        INSERT INTO #Results VALUES ('ASSIGN_PIC', 1, N'Đã gán người phụ trách: ' + @AssignTo, NULL)
                    END TRY
                    BEGIN CATCH
                        INSERT INTO #Results VALUES ('ASSIGN_PIC', 0, N'Lỗi ASSIGN_PIC: ' + ERROR_MESSAGE(), NULL)
                    END CATCH
                END
            END

            -- ── SEND_EMAIL / CROSS_WF_CREATE: ghi hàng đợi (async) ──────────
            ELSE IF @ActionType IN ('SEND_EMAIL', 'CROSS_WF_CREATE')
            BEGIN
                BEGIN TRY
--                    INSERT INTO dbo.tblDebugLog (Message) VALUES (
--                        N'[DBG] Inserting queue: ActionType=' + @ActionType
--                        + N' | Params=' + ISNULL(LEFT(@ActionParamsJSON, 100), N'NULL')
--                    )
                    INSERT INTO dbo.tblWF_AutomationQueue
                        (InstanceID, StepDefID, RuleName, ActionType, ActionParamsJSON, Status, CreateTime, CreateUser)
                    VALUES
                        (@InstanceID, @CurrentStepDefID, @RuleName, @ActionType,
                         ISNULL(@ActionParamsJSON, '{}'), 'QUEUED', GETDATE(), @sys_UserID)

--                    INSERT INTO dbo.tblDebugLog (Message) VALUES (N'[DBG] Queue insert OK for ' + @ActionType)
                    INSERT INTO #Results VALUES (@ActionType, 1, N'Đã ghi hàng đợi: ' + @ActionType, NULL)
                END TRY
                BEGIN CATCH
--                    INSERT INTO dbo.tblDebugLog (Message) VALUES (N'[DBG] Queue insert FAILED: ' + ERROR_MESSAGE())
                    INSERT INTO #Results VALUES (@ActionType, 0, N'Lỗi enqueue: ' + ERROR_MESSAGE(), NULL)
                END CATCH
            END

        END  -- IF @ConditionPassed = 1

        FETCH NEXT FROM rule_cur INTO @RuleJSON
    END

    CLOSE rule_cur
    DEALLOCATE rule_cur

    -- ── Return ────────────────────────────────────────────────────────────────
    IF @InternalCall = 0
    BEGIN
        IF EXISTS(SELECT 1 FROM #Results)
            SELECT ActionType, Success, Message, NewStepDefID FROM #Results
        ELSE
            SELECT NULL AS ActionType, CAST(1 AS BIT) AS Success,
                   N'Không có quy tắc nào khớp sự kiện: ' + @Event AS Message,
                   NULL AS NewStepDefID
    END

    -- ── Process Automation Queue ──────────────────────────────────────────────
    IF @@NESTLEVEL <= 10
    BEGIN
        EXEC dbo.spAPI_WF_AutomationQueue_Process;
    END

    DROP TABLE IF EXISTS #FieldValues
    DROP TABLE IF EXISTS #Results
--
--        INSERT INTO dbo.tblDebugLog (Message)
--        VALUES (N'SUCCESS EXEC spAPI_WF_Automation_Execute - InstanceID: ' + CAST(@InstanceID AS VARCHAR(10)));
    END TRY
    BEGIN CATCH
--        INSERT INTO dbo.tblDebugLog (Message)
--        VALUES (N'ERROR in spAPI_WF_Automation_Execute: ' + ERROR_MESSAGE() 
--                + N', Line: ' + CAST(ERROR_LINE() AS VARCHAR(10)));
        IF @InternalCall = 0
            THROW;
    END CATCH
END
