CREATE PROCEDURE spAPI_HDKH_Field_Delete
    @FieldID INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE tblHDKH_Field_Definition
    SET 
        IsDeleted = 1,
        UpdateTime = GETDATE(),
        UpdateUser = @sys_UserID
    WHERE FieldID = @FieldID;

    SELECT Message = N'Xóa Field thành công.';

END;
