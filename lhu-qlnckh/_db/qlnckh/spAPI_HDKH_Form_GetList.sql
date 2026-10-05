-- Đổi tên từ spAPI_HDKH_@2_Form_GetList thành spAPI_HDKH_Form_GetList
CREATE PROCEDURE spAPI_HDKH_Form_GetList
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FormID,
        FormCode,
        FormTitle,
        SortOrder,
        CreateTime,
        CreateUser,
        UpdateTime,
        UpdateUser
    FROM tblHDKH_Form_Definition
    WHERE IsDeleted = 0
    ORDER BY SortOrder, FormTitle;

END;
