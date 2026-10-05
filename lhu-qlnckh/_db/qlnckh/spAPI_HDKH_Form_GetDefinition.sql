CREATE PROCEDURE dbo.spAPI_HDKH_Form_GetDefinition
    @FormID INT, 
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN

    -- Trả về một object JSON duy nhất, FUI/t-API sẽ tự động bọc trong "data"
    SELECT
        F.FormID,
        F.FormCode,
        F.FormTitle,
        json_data = ( -- Sử dụng json_data để t-API tự động parse thành một thuộc tính tên là "Fields"
            SELECT 
                D.FieldID,
                D.FieldName,
                D.FieldLabel,
                D.FieldType,
                D.FieldGroup,
                D.DataSource,
                D.SortOrder,
                D.IsRequired,
                D.IsUsedForRule
            FROM dbo.tblHDKH_Field_Definition AS D
            WHERE D.FormID = F.FormID AND D.IsDeleted = 0
            ORDER BY D.FieldGroup, D.SortOrder
            FOR JSON PATH
        )
    FROM dbo.tblHDKH_Form_Definition AS F
    WHERE F.FormID = @FormID;

END;
