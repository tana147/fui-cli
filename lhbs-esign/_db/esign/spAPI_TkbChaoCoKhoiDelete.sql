CREATE PROCEDURE spAPI_TkbChaoCoKhoiDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_ChaoCoKhoi SET Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE ID = @ID
    SELECT mess = N'Đã xoá'
END