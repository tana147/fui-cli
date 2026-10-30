-- ------------------------------------------------------------
-- 5. DELETE (soft delete)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[spAPI_WF_CustomFieldMapping_Delete]
    @sys_UserID VARCHAR(9),
    @MappingID  INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_CustomFieldMapping
    SET
        [Enable]   = 1,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MappingID = @MappingID;
END
