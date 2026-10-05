CREATE  PROCEDURE spAPI_HDKH_Form_GetByID
    @FormID INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        FormID,
        FormCode,
        FormTitle
    FROM tblHDKH_Form_Definition
    WHERE FormID = @FormID AND IsDeleted = 0;

END;
