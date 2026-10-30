CREATE PROCEDURE spAPI_TkbDayThayDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_DayThay SET Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE ID = @ID;
    SELECT mess = N'Đã xoá'
END