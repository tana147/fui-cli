CREATE PROCEDURE [dbo].[spAPI_WF_Definition_GetDetail]
    @DefinitionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Thông tin chung về Workflow
    SELECT D.DefinitionID, D.Code, D.Name, D.Description, D.CategoryID, D.Version, D.IsActive, D.OnRejectAction, D.NotifyEmail, D.NotifyOnComplete, D.AssignerID,
           AssignerName = ISNULL(U.FullName, N''),
           D.CreateUser, D.CreateTime, D.UpdateUser, D.UpdateTime, D.[Enable]
    FROM dbo.tblWF_Definition AS D
    OUTER APPLY (
        SELECT TOP (1) U.FullName
        FROM dbo.tblWF_User AS U
        WHERE U.EmployeeCode = D.AssignerID AND U.[Enable] = 1 AND U.IsActive = 1
        ORDER BY U.UserID DESC
    ) AS U
    WHERE D.DefinitionID = @DefinitionID AND D.[Enable] = 1;

    -- 2. Danh sách các bước (Steps) kèm Signers, Tasks, Assignees lồng nhau dạng JSON
    SELECT S.StepDefID,
           S.DefinitionID,
           S.StepOrder,
           S.StepCode,
           S.StepName,
           S.StepType,
           S.SignSystem,
           S.TemplateID,
           T.TemplateName,
           S.TemplatesJSON,  -- [MULTI-TEMPLATE] array of template slots
           S.AutoTrigger,
           S.IsRequired,
           S.OnRejectGoToStep,
           S.ConditionJSON,
           S.DueHours,
           S.DueType,
           S.Description,
           S.CreateUser,
           S.CreateTime,
           S.UpdateUser,
           S.UpdateTime,
           -- [MULTI-TEMPLATE] SignersJSON kèm TemplateSlotIdx để FE biết signer thuộc slot nào
           (SELECT SD.StepSignerDefID,
                   SD.StepDefID,
                   SD.SignerOrder,
                   SD.SignerType,
                   SD.SignerValue,
                   SD.SignMethod,
                   SD.IsSequential,
                   SD.TemplateSlotIdx
            FROM dbo.tblWF_StepSignerDef AS SD
            WHERE SD.StepDefID = S.StepDefID
              AND SD.[Enable] = 1
            ORDER BY SD.TemplateSlotIdx, SD.SignerOrder
            FOR JSON PATH) AS SignersJSON,
           (SELECT TK.TaskID,
                   TK.StepDefID,
                   TK.TaskName,
                   TK.DueHours,
                   TK.Description,
                   TK.IsCompleted,
                   TK.IsRequired,
                   TK.IsLocked,
                   TK.IsDeleted,
                   TK.SortOrder,
                   TK.CreateUser,
                   TK.CreateTime,
                   TK.UpdateUser,
                   TK.UpdateTime
            FROM dbo.tblWF_Task AS TK
            WHERE TK.StepDefID = S.StepDefID
            ORDER BY TK.SortOrder, TK.TaskID
            FOR JSON PATH) AS TasksJSON,
           (SELECT SA.StepAssigneeID,
                   SA.StepDefID,
                   ISNULL(SA.EmployeeID, 0) AS EmployeeID, -- Đảm bảo luôn có trường này
                   ISNULL(P.EmployeeCode, '') AS EmployeeCode,
                   ISNULL(P.FullName, '') AS FullName,
                   SA.RoleCode,
                   SA.RightCode
            FROM dbo.tblWF_StepAssignee AS SA
            LEFT JOIN dbo.tblWF_User P ON SA.EmployeeID = P.UserID
            WHERE SA.StepDefID = S.StepDefID
              AND SA.[Enable] = 1
            FOR JSON PATH) AS AssigneesJSON
    FROM dbo.tblWF_StepDefinition AS S
             LEFT JOIN dbo.tblWF_Template AS T
                       ON T.TemplateID = S.TemplateID
                           AND T.[Enable] = 1
    WHERE S.DefinitionID = @DefinitionID
      AND S.[Enable] = 1
    ORDER BY S.StepOrder;

    -- 3. Danh sách trường dữ liệu (Fields)
    SELECT F.MappingID,
           F.DefinitionID,
           F.FieldName,
           F.FieldLabel,
           F.FieldType,
           F.FieldOptions,
           F.InputAtStep,
           F.IsRequired,
           F.DefaultValue,
           F.SortOrder,
           F.CreateUser,
           F.CreateTime,
           F.UpdateUser,
           F.UpdateTime
    FROM dbo.tblWF_FieldMapping AS F
    WHERE F.DefinitionID = @DefinitionID
      AND F.[Enable] = 1
    ORDER BY F.SortOrder, F.MappingID;
END

