CREATE PROCEDURE spAPI_TkbDinhMucTietDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_DinhMucTiet SET Enable = 0 WHERE ID = @ID;
END