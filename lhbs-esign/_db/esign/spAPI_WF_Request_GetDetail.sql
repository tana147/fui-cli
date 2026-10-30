CREATE PROCEDURE [dbo].[spAPI_WF_Request_GetDetail]
    @InstanceID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblWF_Instance
        WHERE InstanceID = @InstanceID
          AND [Enable] = 1
    )
    BEGIN
        RAISERROR(N'Không tìm thấy yêu cầu ký.', 16, 1);
        RETURN;
    END

    ;WITH CurrentAction AS
    (
        SELECT TOP (1)
            EX.ExecutionID,
            EX.StepOrder,
            SE.SignerExecID,
            -- Ưu tiên giá trị từ sig field ({{sig_x}} / ###sig_x###); fallback về DB
            ISNULL(SFD.FieldEmpCode,   SE.ResolvedPersonID)   AS ResolvedPersonID,
            ISNULL(SFU.FullName, ISNULL(SFD.FieldEmpCode, SE.ResolvedPersonName)) AS ResolvedPersonName,
            SE.SignMethod,
            EX.Status AS ExecutionStatus,
            SE.Status AS SignerStatus
        FROM dbo.tblWF_StepExecution AS EX
        INNER JOIN dbo.tblWF_Instance AS INST
            ON INST.InstanceID = EX.InstanceID
           AND INST.[Enable] = 1
           AND INST.CurrentStepOrder = EX.StepOrder
        INNER JOIN dbo.tblWF_StepSignerExec AS SE
            ON SE.ExecutionID = EX.ExecutionID
           AND SE.[Enable] = 1
        OUTER APPLY
        (
            -- Dùng StepOrder + SignerOrder để tìm LabelText (không phụ thuộc ExecutionID)
            -- vì sign boxes có thể thuộc execution cũ nhưng field name vẫn đúng
            SELECT TOP 1
                NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') AS FieldEmpCode
            FROM dbo.tblWF_InstanceSignBox AS SB
            INNER JOIN dbo.tblWF_InstanceData AS ID
                ON  ID.InstanceID = @InstanceID
                AND ID.[Enable]   = 1
                AND ID.FieldName  =
                    CASE
                        WHEN SB.LabelText LIKE '{{%}}'
                            THEN SUBSTRING(SB.LabelText, 3, LEN(SB.LabelText) - 4)
                        WHEN SB.LabelText LIKE '###%###'
                            THEN SUBSTRING(SB.LabelText, 4, LEN(SB.LabelText) - 6)
                        ELSE SB.LabelText
                    END
            WHERE SB.InstanceID   = @InstanceID
              AND SB.StepOrder    = EX.StepOrder
              AND SB.SignerOrder  = SE.SignerOrder
              AND SB.[Enable]     = 1
              AND NULLIF(LTRIM(RTRIM(ID.FieldValue)), '') IS NOT NULL
        ) AS SFD
        OUTER APPLY
        (
            SELECT TOP 1 U.FullName
            FROM dbo.tblWF_User AS U
            WHERE U.[Enable]                         = 1
              AND ISNULL(U.IsActive, 1)             = 1
              AND UPPER(ISNULL(U.EmployeeCode, '')) = UPPER(ISNULL(SFD.FieldEmpCode, ''))
            ORDER BY U.UserID DESC
        ) AS SFU
        WHERE EX.InstanceID = @InstanceID
          AND EX.[Enable]   = 1
          AND EX.Status IN ('ACTIVE', 'SIGNING')
          AND UPPER(EX.StepType) IN ('SIGN', 'APPROVE', 'REVIEW') -- 🟢 Chỉ lấy lượt ký ở các bước duyệt/ký thực sự
          AND SE.Status     = 'WAITING'
        ORDER BY EX.StepOrder, SE.SignerOrder
    )
    -- RS1: Thông tin Instance + trạng thái bước hiện tại
    SELECT
        I.InstanceID,
        I.InstanceName,
        I.DefinitionID,
        I.CreateMode,
        DefinitionCode = ISNULL(D.Code, CASE WHEN I.CreateMode = 'FREE_SIGN' THEN 'FREE_SIGN' ELSE '' END),
        DefinitionName = ISNULL(D.Name, CASE WHEN I.CreateMode = 'FREE_SIGN' THEN N'Ký tự do' ELSE N'' END),
        DefinitionDescription = ISNULL(NULLIF(I.Description, N''), ISNULL(D.Description, N'')),
        DefinitionVersion = ISNULL(D.Version, 1),
        CategoryID = ISNULL(I.CategoryID, D.CategoryID),
        C.Code AS CategoryCode,
        C.Name AS CategoryName,
        I.ReferenceCode,
        I.Description,
        I.ExecutionEngine,
        I.ContractProvider,
        I.ExternalContractID,
        I.ExternalContractStatusCode,
        I.ExternalContractStatusText,
        I.ExternalSignStatusCode,
        I.ExternalSignStatusText,
        I.ExternalLastSyncTime,
        I.SourceFileID,
        I.SourceFileName,
        I.Status,
        I.CurrentStepOrder,
        CS.ExecutionID AS CurrentExecutionID,
        CS.StepDefID AS CurrentStepDefID,
        CurrentStepCode = ISNULL(CS.StepCode, ISNULL(SD.StepCode, '')),
        CurrentStepName = ISNULL(CS.StepName, ISNULL(SD.StepName, '')),
        CurrentStepType = ISNULL(CS.StepType, ISNULL(SD.StepType, '')),
        CurrentSignSystem = ISNULL(CS.SignSystem, ISNULL(SD.SignSystem, '')),
        CurrentTemplateID = ISNULL(CS.TemplateID, SD.TemplateID),
        CurrentTemplateName = ISNULL(TC.TemplateName, ISNULL(T.TemplateName, '')),
        CurrentTemplateFileUrl = ISNULL(TC.FileUrl, ISNULL(T.FileUrl, '')),
        -- [MULTI-TEMPLATE] TemplatesJSON của bước hiện tại (ưu tiên từ execution, fallback về definition)
        CurrentTemplatesJSON = ISNULL(CS.TemplatesJSON, SD.TemplatesJSON),
        CS.DocumentFileUrl AS CurrentDocumentFileUrl,
        CS.DocumentFileID AS CurrentDocumentFileID,
        CurrentDocumentFileName = ISNULL(CS.DocumentFileName, ISNULL(I.SourceFileName, '')),
        RequireManualSendSign = CAST(ISNULL(CS.RequireManualSendSign, ISNULL(SD.RequireManualSendSign, 0)) AS BIT),
        IsSentForSigning = CAST(CASE WHEN CS.DocumentFileID IS NOT NULL THEN 1 ELSE 0 END AS BIT),
        TS.TotalSteps,
        CA.SignerExecID AS CurrentSignerExecID,
        CA.ResolvedPersonID AS CurrentSignerPersonID,
        CA.ResolvedPersonName AS CurrentSignerPersonName,
        CA.SignMethod AS CurrentSignerMethod,
        CAST(CASE WHEN ISNULL(CA.ResolvedPersonID, '') = @sys_UserID THEN 1 ELSE 0 END AS BIT) AS CanCurrentUserSign,
        CAST(CASE WHEN ISNULL(CA.ResolvedPersonID, '') = @sys_UserID THEN 1 ELSE 0 END AS BIT) AS CanCurrentUserReject,
        -- 🟢 Check quyền xử lý chung ở bước hiện tại từ bảng thực thi gán quyền mới tblWF_StepAssigneeExec hoặc là người phụ trách quy trình/người tạo
        CAST(CASE WHEN EXISTS (
            SELECT 1
            FROM dbo.tblWF_StepAssigneeExec AS AE
            WHERE AE.ExecutionID = CS.ExecutionID
              AND AE.EmployeeCode = @sys_UserID
              AND AE.Status       = 'ACTIVE'
              AND AE.[Enable]     = 1
        ) OR ISNULL(I.AssigneeCode, '') = @sys_UserID
          OR ISNULL(I.CreateUser, '') = @sys_UserID
        THEN 1 ELSE 0 END AS BIT) AS CanCurrentUserAct,
        I.AssigneeCode,
        AssigneeName = U_Assign.FullName,
        NextSigner = ISNULL(CA.ResolvedPersonName, ISNULL(AE.AssigneeNames, ISNULL(U_Assign.FullName, N'-'))),
        I.CreateUser,
        I.CreateTime,
        I.UpdateUser,
        I.UpdateTime
    FROM dbo.tblWF_Instance AS I
    LEFT JOIN dbo.tblWF_User AS U_Assign
        ON U_Assign.EmployeeCode = I.AssigneeCode
       AND U_Assign.[Enable] = 1
    LEFT JOIN dbo.tblWF_Definition AS D
        ON D.DefinitionID = I.DefinitionID
       AND D.[Enable] = 1
    LEFT JOIN dbo.tblWF_Category AS C
        ON C.CategoryID = ISNULL(I.CategoryID, D.CategoryID)
       AND C.[Enable] = 1
    OUTER APPLY
    (
        SELECT COUNT(1) AS TotalSteps
        FROM dbo.tblWF_StepExecution AS EX
        WHERE EX.InstanceID = I.InstanceID
          AND EX.[Enable] = 1
    ) AS TS
    OUTER APPLY
    (
        SELECT TOP (1)
            EX.ExecutionID,
            EX.StepDefID,
            EX.StepCode,
            EX.StepName,
            EX.StepType,
            EX.SignSystem,
            EX.TemplateID,
            EX.TemplatesJSON,  -- [MULTI-TEMPLATE]
            EX.DocumentFileUrl,
            EX.DocumentFileID,
            EX.DocumentFileName,
            EX.RequireManualSendSign
        FROM dbo.tblWF_StepExecution AS EX
        WHERE EX.InstanceID = I.InstanceID
          AND EX.StepOrder = I.CurrentStepOrder
          AND EX.[Enable] = 1
        ORDER BY EX.ExecutionID DESC
    ) AS CS
    LEFT JOIN dbo.tblWF_StepDefinition AS SD
        ON SD.StepDefID = CS.StepDefID
       AND SD.[Enable] = 1
    LEFT JOIN dbo.tblWF_Template AS T
        ON T.TemplateID = SD.TemplateID
       AND T.[Enable] = 1
    LEFT JOIN dbo.tblWF_Template AS TC
        ON TC.TemplateID = CS.TemplateID
       AND TC.[Enable] = 1
    OUTER APPLY
    (
        SELECT AssigneeNames = STUFF((
            SELECT ', ' + FullName
            FROM dbo.tblWF_StepAssigneeExec
            WHERE ExecutionID = CS.ExecutionID
              AND [Enable] = 1
              AND Status = 'ACTIVE'
            FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, '')
    ) AS AE
    OUTER APPLY
    (
        SELECT TOP (1) *
        FROM CurrentAction
    ) AS CA
    WHERE I.InstanceID = @InstanceID
      AND I.[Enable] = 1;

    -- RS2: Danh sách tất cả StepExecution của instance
    SELECT
        EX.ExecutionID,
        EX.InstanceID,
        EX.StepDefID,
        EX.StepOrder,
        StepCode = ISNULL(EX.StepCode, ISNULL(SD.StepCode, '')),
        StepName = ISNULL(EX.StepName, ISNULL(SD.StepName, '')),
        StepType = ISNULL(EX.StepType, ISNULL(SD.StepType, '')),
        SignSystem = ISNULL(EX.SignSystem, ISNULL(SD.SignSystem, '')),
        TemplateID = ISNULL(EX.TemplateID, SD.TemplateID),
        TemplateName = ISNULL(TX.TemplateName, ISNULL(T.TemplateName, '')),
        -- [MULTI-TEMPLATE] TemplatesJSON của step (ưu tiên từ execution, fallback về definition)
        TemplatesJSON = ISNULL(EX.TemplatesJSON, SD.TemplatesJSON),
        EX.Status,
        EX.DocumentFileUrl,
        EX.DocumentFileID,
        EX.DocumentFileName,
        EX.SignTransactionID,
        EX.StartedDate,
        EX.CompletedDate,
        EX.RejectedBy,
        EX.RejectedReason,
        EX.RejectedDate,
        TotalSignerCount = ISNULL(SX.TotalSignerCount, 0),
        SignedCount = ISNULL(SX.SignedCount, 0),
        WaitingCount = ISNULL(SX.WaitingCount, 0),
        PendingCount = ISNULL(SX.PendingCount, 0),
        CurrentUserCanAct = CAST(CASE WHEN ISNULL(SX.CurrentUserWaitingCount, 0) > 0 THEN 1 ELSE 0 END AS BIT)
    FROM dbo.tblWF_StepExecution AS EX
    LEFT JOIN dbo.tblWF_StepDefinition AS SD
        ON SD.StepDefID = EX.StepDefID
       AND SD.[Enable] = 1
    LEFT JOIN dbo.tblWF_Template AS T
        ON T.TemplateID = SD.TemplateID
       AND T.[Enable] = 1
    LEFT JOIN dbo.tblWF_Template AS TX
        ON TX.TemplateID = EX.TemplateID
       AND TX.[Enable] = 1
    OUTER APPLY
    (
        SELECT
            COUNT(1) AS TotalSignerCount,
            SUM(CASE WHEN SE.Status = 'SIGNED' THEN 1 ELSE 0 END) AS SignedCount,
            SUM(CASE WHEN SE.Status = 'WAITING' THEN 1 ELSE 0 END) AS WaitingCount,
            SUM(CASE WHEN SE.Status = 'PENDING' THEN 1 ELSE 0 END) AS PendingCount,
            SUM(CASE WHEN SE.Status = 'WAITING' AND SE.ResolvedPersonID = @sys_UserID THEN 1 ELSE 0 END) AS CurrentUserWaitingCount
        FROM dbo.tblWF_StepSignerExec AS SE
        WHERE SE.ExecutionID = EX.ExecutionID
          AND SE.[Enable] = 1
    ) AS SX
    WHERE EX.InstanceID = @InstanceID
      AND EX.[Enable] = 1
    ORDER BY EX.StepOrder, EX.ExecutionID;

    -- RS3: Danh sách tất cả Signer của instance (kèm TemplateSlotIdx cho multi-template)
    SELECT
        SE.SignerExecID,
        SE.ExecutionID,
        EX.StepOrder,
        StepName = ISNULL(EX.StepName, ISNULL(SD.StepName, '')),
        StepType = ISNULL(EX.StepType, ISNULL(SD.StepType, '')),
        SE.SignerOrder,
        SE.SignerType,
        SE.SignerValue,
        SE.DepartmentName,
        SE.TemplateSlotIdx,  -- [MULTI-TEMPLATE] FE dùng để nhóm signer theo template slot
        -- Ưu tiên giá trị từ sig field (tblWF_InstanceData) nếu có; fallback về DB
        ISNULL(SFD2.FieldEmpCode,   SE.ResolvedPersonID)   AS ResolvedPersonID,
        ISNULL(SFU2.FullName, ISNULL(SFD2.FieldEmpCode, SE.ResolvedPersonName)) AS ResolvedPersonName,
        SE.SignMethod,
        SE.Status,
        SE.SignedDate,
        SE.SignCertInfo,
        CAST(CASE WHEN ISNULL(SFD2.FieldEmpCode, SE.ResolvedPersonID) = @sys_UserID THEN 1 ELSE 0 END AS BIT) AS IsCurrentUser
    FROM dbo.tblWF_StepSignerExec AS SE
    INNER JOIN dbo.tblWF_StepExecution AS EX
        ON EX.ExecutionID = SE.ExecutionID
       AND EX.[Enable] = 1
    LEFT JOIN dbo.tblWF_StepDefinition AS SD
        ON SD.StepDefID = EX.StepDefID
       AND SD.[Enable] = 1
    OUTER APPLY
    (
        -- Dùng StepOrder + SignerOrder để match, không dùng SignerExecID
        SELECT TOP 1
            NULLIF(LTRIM(RTRIM(ID2.FieldValue)), '') AS FieldEmpCode
        FROM dbo.tblWF_InstanceSignBox AS SB2
        INNER JOIN dbo.tblWF_InstanceData AS ID2
            ON  ID2.InstanceID = EX.InstanceID
            AND ID2.[Enable]   = 1
            AND ID2.FieldName  =
                CASE
                    WHEN SB2.LabelText LIKE '{{%}}'
                        THEN SUBSTRING(SB2.LabelText, 3, LEN(SB2.LabelText) - 4)
                    WHEN SB2.LabelText LIKE '###%###'
                        THEN SUBSTRING(SB2.LabelText, 4, LEN(SB2.LabelText) - 6)
                    ELSE SB2.LabelText
                END
        WHERE SB2.InstanceID  = EX.InstanceID
          AND SB2.StepOrder   = EX.StepOrder
          AND SB2.SignerOrder  = SE.SignerOrder
          AND SB2.[Enable]     = 1
          AND NULLIF(LTRIM(RTRIM(ID2.FieldValue)), '') IS NOT NULL
    ) AS SFD2
    OUTER APPLY
    (
        SELECT TOP 1 U2.FullName
        FROM dbo.tblWF_User AS U2
        WHERE U2.[Enable]                         = 1
          AND ISNULL(U2.IsActive, 1)             = 1
          AND UPPER(ISNULL(U2.EmployeeCode, '')) = UPPER(ISNULL(SFD2.FieldEmpCode, ''))
        ORDER BY U2.UserID DESC
    ) AS SFU2
    WHERE EX.InstanceID = @InstanceID
      AND SE.[Enable]   = 1
    ORDER BY EX.StepOrder, SE.TemplateSlotIdx, SE.SignerOrder;  -- [MULTI-TEMPLATE] order by slot trước

    -- RS4: Dữ liệu các field
    SELECT
        ID.InstanceDataID,
        ID.InstanceID,
        ID.FieldName,
        FM.FieldLabel,
        FM.FieldType,
        FM.FieldOptions,
        ID.FieldValue,
        ID.UpdatedAtStep,
        FM.SortOrder
    FROM dbo.tblWF_InstanceData AS ID
    LEFT JOIN dbo.tblWF_Instance AS I
        ON I.InstanceID = ID.InstanceID
       AND I.[Enable] = 1
    LEFT JOIN dbo.tblWF_FieldMapping AS FM
        ON FM.DefinitionID = I.DefinitionID
       AND FM.FieldName = ID.FieldName
       AND FM.[Enable] = 1
    WHERE ID.InstanceID = @InstanceID
      AND ID.[Enable] = 1
    ORDER BY ISNULL(FM.SortOrder, 9999), ID.InstanceDataID;

    -- RS5: Audit log
    SELECT
        LogID,
        InstanceID,
        StepOrder,
        ActionCode,
        ActionDetail,
        UserID,
        CreateTime
    FROM dbo.tblWF_AuditLog
    WHERE InstanceID = @InstanceID
      AND [Enable] = 1
    ORDER BY CreateTime DESC, LogID DESC;

    -- RS6: Sign boxes (kèm TemplateSlotIdx cho multi-template)
    SELECT
        InstanceSignBoxID,
        InstanceID,
        ExecutionID,
        SignerExecID,
        BoxOrder,
        PageNo,
        PosX,
        PosY,
        BoxWidth,
        BoxHeight,
        StepOrder,
        SignerOrder,
        SignerType,
        SignerValue,
        PersonName,
        DepartmentName,
        SignMethod,
        ExecutionEngine,
        ContractProvider,
        LabelText,
        Status,
        TemplateSlotIdx  -- [MULTI-TEMPLATE] FE dùng để biết sign box thuộc PDF nào
    FROM dbo.tblWF_InstanceSignBox
    WHERE InstanceID = @InstanceID
      AND [Enable] = 1
    ORDER BY BoxOrder, InstanceSignBoxID;
END

