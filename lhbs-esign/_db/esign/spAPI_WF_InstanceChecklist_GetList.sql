CREATE PROCEDURE [dbo].[spAPI_WF_InstanceChecklist_GetList]
    @InstanceID BIGINT,
    @StepDefID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    -- Lay danh muc checklist duoc thiet lap cho buoc hien tai,
    -- ket hop voi trang thai thuc te cua tung ung vien (InstanceID)
    SELECT 
        d.ChecklistDefID,
        d.StepDefID,
        d.ItemCode,
        d.ItemName,
        d.[Description],
        d.IsRequired,
        d.AllowedMethods,
        d.AllowDefer,
        ISNULL(i.InstanceChecklistID, 0) AS InstanceChecklistID,
        ISNULL(i.IsCompleted, 0) AS IsCompleted,
        i.SubmitMethod,
        i.AttachmentUrl,
        ISNULL(i.IsDeferred, 0) AS IsDeferred,
        i.DeferredDueDate,
        i.Note
    FROM dbo.tblWF_StepChecklistDef d
    LEFT JOIN dbo.tblWF_InstanceChecklist i 
        ON d.ChecklistDefID = i.ChecklistDefID 
        AND i.InstanceID = @InstanceID 
        AND i.[Enable] = 1
    WHERE d.StepDefID = @StepDefID AND d.[Enable] = 1
    ORDER BY d.ChecklistDefID ASC;
END
