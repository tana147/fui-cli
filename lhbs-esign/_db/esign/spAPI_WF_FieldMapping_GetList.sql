CREATE PROCEDURE [dbo].[spAPI_WF_FieldMapping_GetList]
    @sys_UserID VARCHAR(9),
    @DefinitionID BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        DefinitionID,
        FieldName,
        FieldLabel,
        FieldType, -- Dùng cột này là đủ
        IsRequired,
        SortOrder,
        [Enable]
    FROM dbo.tblWF_FieldMapping
    WHERE DefinitionID = @DefinitionID
      AND [Enable] = 1
    ORDER BY SortOrder;
END
