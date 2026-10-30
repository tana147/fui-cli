
    CREATE PROCEDURE [dbo].[spAPI_WF_Instance_GetMyAssignedList]
        @sys_UserID VARCHAR(9),
        @DefinitionID BIGINT = NULL,
        @Filter VARCHAR(20) = 'ALL'
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            I.InstanceID,
            I.InstanceName,
            I.DefinitionID,
            I.CurrentStepOrder,
            CurrentStepDefID = CS.StepDefID,
            CurrentStepName = ISNULL(CS.StepName, ISNULL(SD.StepName, N'-')),
            DefinitionName = ISNULL(D.Name, CASE WHEN I.CreateMode = 'FREE_SIGN' THEN N'Ký tự do' ELSE N'-' END),
            I.Status,
            I.CreateUser,
            I.CreateTime,
            I.UpdateUser,
            I.UpdateTime,
            I.TagIDList AS Tag,
            AssigneeCode = I.AssigneeCode,
            AssigneeName = ISNULL(U_Assign.FullName, N'-'),
            NextSigner = ISNULL(NS.ResolvedPersonName, N'-'),
            StepExecutionStatus = CS.Status,
            
            ChecklistJSON = (
                SELECT 
                    ChecklistDefID = FM.FieldName, 
                    ItemName = FM.FieldLabel,      
                    IsCompleted = CASE WHEN ID.FieldValue IS NOT NULL AND ID.FieldValue <> '' THEN 1 ELSE 0 END
                FROM dbo.tblWF_FieldMapping AS FM
                LEFT JOIN dbo.tblWF_InstanceData AS ID 
                    ON ID.FieldName = FM.FieldName 
                   AND ID.InstanceID = I.InstanceID
                   AND ID.[Enable] = 1
                WHERE FM.DefinitionID = I.DefinitionID 
                  AND (',' + FM.InputAtStep + ',') LIKE ('%,' + CAST(I.CurrentStepOrder AS VARCHAR(10)) + ',%')
                  AND FM.FieldType = 'file'
                  AND FM.[Enable] = 1
                FOR JSON PATH
            ),
            TasksJSON = (
                SELECT 
                    TaskID = T.TaskID,
                    TaskName = T.TaskName,
                    Status = T.Status
                FROM dbo.tblWF_InstanceTask AS T
                WHERE T.InstanceID = I.InstanceID
                  AND T.StepDefID = CS.StepDefID
                  AND T.[Enable] = 1
                FOR JSON PATH
            )
        FROM dbo.tblWF_Instance AS I
        LEFT JOIN dbo.tblWF_Definition AS D
            ON D.DefinitionID = I.DefinitionID
           AND D.[Enable] = 1
        OUTER APPLY
        (
            SELECT TOP (1) U.FullName
            FROM dbo.tblWF_User AS U
            WHERE U.EmployeeCode = I.AssigneeCode
              AND U.[Enable] = 1
              AND U.IsActive = 1
            ORDER BY U.UserID DESC
        ) AS U_Assign
        OUTER APPLY
        (
            SELECT TOP (1)
                EX.StepName,
                EX.StepDefID,
                EX.Status
            FROM dbo.tblWF_StepExecution AS EX
            WHERE EX.InstanceID = I.InstanceID
              AND EX.StepOrder = I.CurrentStepOrder
              AND EX.[Enable] = 1
            ORDER BY EX.ExecutionID DESC
        ) AS CS
        LEFT JOIN dbo.tblWF_StepDefinition AS SD
            ON SD.StepDefID = CS.StepDefID
           AND SD.[Enable] = 1
        OUTER APPLY
        (
            SELECT TOP (1)
                ResolvedPersonName = ISNULL(SE.ResolvedPersonName, AE.AssigneeNames)
            FROM dbo.tblWF_StepExecution AS EX
            LEFT JOIN dbo.tblWF_StepSignerExec AS SE
                ON SE.ExecutionID = EX.ExecutionID
               AND SE.[Enable] = 1
               AND SE.Status IN ('WAITING', 'PENDING')
            OUTER APPLY
            (
                SELECT AssigneeNames = STUFF((
                    SELECT ', ' + FullName
                    FROM dbo.tblWF_StepAssigneeExec
                    WHERE ExecutionID = EX.ExecutionID
                      AND [Enable] = 1
                      AND Status = 'ACTIVE'
                    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
            ) AS AE
            WHERE EX.InstanceID = I.InstanceID
              AND EX.StepOrder = I.CurrentStepOrder
              AND EX.[Enable] = 1
            ORDER BY CASE WHEN SE.SignerExecID IS NOT NULL THEN 0 ELSE 1 END, SE.SignerOrder
        ) AS NS
        WHERE I.[Enable] = 1
          AND (
              I.AssigneeCode = @sys_UserID
              OR EXISTS (
                  SELECT 1
                  FROM dbo.tblWF_StepExecution AS EX2
                  INNER JOIN dbo.tblWF_StepSignerExec AS SE2
                      ON SE2.ExecutionID = EX2.ExecutionID
                     AND SE2.[Enable] = 1
                  WHERE EX2.InstanceID = I.InstanceID
                    AND EX2.StepOrder = I.CurrentStepOrder
                    AND EX2.Status IN ('ACTIVE', 'SIGNING')
                    AND SE2.ResolvedPersonID = @sys_UserID
              )
          )
          AND (@DefinitionID IS NULL OR I.DefinitionID = @DefinitionID)
          AND
          (
              @Filter = 'ALL'
              OR (@Filter = 'RUNNING' AND I.Status = 'RUNNING')
              OR (@Filter = 'WAITING_ME' AND I.Status = 'WAITING_ME')
              OR (@Filter = 'COMPLETED' AND I.Status = 'COMPLETED')
              OR (@Filter = 'CANCELLED' AND I.Status = 'CANCELLED')
          )
        ORDER BY I.CreateTime DESC, I.InstanceID DESC;
    END
    