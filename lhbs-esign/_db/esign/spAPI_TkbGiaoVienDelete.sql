CREATE PROCEDURE spAPI_TkbGiaoVienDelete
    @url1_MaGV  varchar(15),
    @sys_UserID varchar(9)
AS
BEGIN
    UPDATE tblTKB_GiaoVien
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaGV = @url1_MaGV

    SELECT mess = N'Đã xoá', id = @url1_MaGV
END
