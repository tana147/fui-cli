CREATE PROCEDURE spAPI_TkbGiaoVienListTheoTo
    @To         nvarchar(50),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT MaGV, HoTen, PhongBanChucVu
    FROM tblTKB_GiaoVien
    WHERE Enable = 1
      AND (@To = '' OR PhongBanChucVu LIKE N'%' + @To + N'%' OR GhiChu LIKE N'%' + @To + N'%')
    ORDER BY HoTen
END
