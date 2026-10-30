CREATE PROCEDURE [dbo].[spAPI_WF_StepChecklistDef_GetList]
    @StepDefID BIGINT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ChecklistDefID,
        StepDefID,
        ItemCode,
        ItemName,
        [Description],
        IsRequired,
        AllowedMethods,
        AllowDefer,
        [Enable]
    FROM dbo.tblWF_StepChecklistDef
    WHERE StepDefID = @StepDefID AND [Enable] = 1
    ORDER BY ChecklistDefID ASC;
END
