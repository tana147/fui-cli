CREATE PROCEDURE [dbo].[spAPI_WF_Definition_GetDetail_BK]
    @DefinitionID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        D.DefinitionID,
        D.Code,
        D.Name,
        D.Description,
        D.CategoryID,
        C.Code AS CategoryCode,
        C.Name AS CategoryName,
        C.Color AS CategoryColor,
        C.Icon AS CategoryIcon,
        D.Version,
        D.IsActive,
        D.OnRejectAction,
        D.NotifyEmail,
        D.NotifyOnComplete,
        D.CreateUser,
        D.CreateTime,
        D.UpdateUser,
        D.UpdateTime
    FROM dbo.tblWF_Definition AS D
    LEFT JOIN dbo.tblWF_Category AS C
        ON C.CategoryID = D.CategoryID
       AND C.[Enable] = 0
    WHERE D.DefinitionID = @DefinitionID
      AND D.[Enable] = 0;

    SELECT
        S.StepDefID,
        S.DefinitionID,
        S.StepOrder,
        S.StepCode,
        S.StepName,
        S.StepType,
        S.SignSystem,
        S.TemplateID,
        T.TemplateName,
        T.FileName,
        T.FileType,
        T.PlaceholderJSON,
        S.AutoTrigger,
        S.IsRequired,
        S.OnRejectGoToStep,
        S.ConditionJSON,
        S.CreateUser,
        S.CreateTime,
        S.UpdateUser,
        S.UpdateTime,
        (
            SELECT
                SD.StepSignerDefID,
                SD.StepDefID,
                SD.SignerOrder,
                SD.SignerType,
                SD.SignerValue,
                SD.SignMethod,
                SD.IsSequential
            FROM dbo.tblWF_StepSignerDef AS SD
            WHERE SD.StepDefID = S.StepDefID
              AND SD.[Enable] = 0
            ORDER BY SD.SignerOrder
            FOR JSON PATH
        ) AS SignersJSON
    FROM dbo.tblWF_StepDefinition AS S
    LEFT JOIN dbo.tblWF_Template AS T
        ON T.TemplateID = S.TemplateID
       AND T.[Enable] = 0
    WHERE S.DefinitionID = @DefinitionID
      AND S.[Enable] = 0
    ORDER BY S.StepOrder;

    SELECT
        F.MappingID,
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
      AND F.[Enable] = 0
    ORDER BY F.SortOrder, F.MappingID;
END
