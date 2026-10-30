CREATE PROCEDURE spAPI_TkbLichHopCoDinhDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_LichHopCoDinh SET Enable = 0 WHERE ID = @ID
    SELECT mess = N'Đã xoá'
END