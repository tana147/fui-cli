-- ------------------------------------------------------------
-- 1. GET LIST (by CategoryID)
-- ------------------------------------------------------------
CREATE PROCEDURE [dbo].[spAPI_WF_CustomFieldMapping_GetList]
    @sys_UserID VARCHAR(9),
    @CategoryID INT = 0          -- 0 => lấy tất cả
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        M.MappingID,
        M.CategoryID,
        C.Name          AS CategoryName,
        M.FieldName,
        M.FieldLabel,
        M.FieldType,
        M.FieldOptions,
        M.IsRequired,
        M.DefaultValue,
        M.SortOrder,
        M.CreateUser,
        M.CreateTime,
        M.UpdateUser,
        M.UpdateTime
    FROM dbo.tblWF_CustomFieldMapping AS M
    INNER JOIN dbo.tblWF_Category     AS C ON C.CategoryID = M.CategoryID
    WHERE M.[Enable] = 0
      AND (@CategoryID = 0 OR M.CategoryID = @CategoryID)
    ORDER BY M.SortOrder, M.MappingID;
END
