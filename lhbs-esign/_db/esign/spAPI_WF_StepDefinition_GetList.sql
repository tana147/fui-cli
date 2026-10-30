
    CREATE PROCEDURE [dbo].[spAPI_WF_StepDefinition_GetList]
        @sys_UserID VARCHAR(9),
        @DefinitionID BIGINT
    AS
    BEGIN
        SELECT StepDefID, StepName, StepOrder, Color, DueHours, DueType, Description, StepType, StepCode
        FROM dbo.tblWF_StepDefinition
        WHERE DefinitionID = @DefinitionID AND [Enable] = 1
        ORDER BY StepOrder;
    END
    