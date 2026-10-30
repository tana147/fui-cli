CREATE PROCEDURE spAPI_TkbLopDelete
    @url1_MaLop varchar(10),
    @sys_UserID varchar(9)
AS
BEGIN
    UPDATE tblTKB_Lop
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaLop = @url1_MaLop

    SELECT mess = N'Đã xoá', id = @url1_MaLop
END
