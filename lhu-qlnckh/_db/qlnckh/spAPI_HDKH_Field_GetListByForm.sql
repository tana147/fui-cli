-- Đổi tên từ spAPI_HDKH_@2_Field_GetListByForm thành spAPI_HDKH_Field_GetListByForm
CREATE  PROCEDURE spAPI_HDKH_Field_GetListByForm
    @FormID INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FieldID, FormID, FieldName, FieldLabel, FieldType, FieldGroup,
        DataSource, SortOrder, IsRequired, IsUsedForRule
    FROM tblHDKH_Field_Definition
    WHERE FormID = @FormID AND IsDeleted = 0
    ORDER BY FieldGroup, SortOrder;

END;
