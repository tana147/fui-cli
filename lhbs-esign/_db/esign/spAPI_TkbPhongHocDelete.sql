CREATE PROCEDURE spAPI_TkbPhongHocDelete
    @url1_MaPhong varchar(10),
    @sys_UserID   varchar(9)
AS
BEGIN
    UPDATE tblTKB_PhongHoc
    SET Enable = 0,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaPhong = @url1_MaPhong

    SELECT mess = N'Đã xoá', id = @url1_MaPhong
END
