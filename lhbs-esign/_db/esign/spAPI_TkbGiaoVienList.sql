CREATE PROCEDURE spAPI_TkbGiaoVienList
    @Keyword     nvarchar(100),
    @ChiThinhGiang bit,
    @sys_UserID  varchar(9)
AS
BEGIN
    SELECT MaGV, HoTen, LaThinhGiang, BuoiBanCoDinh, GhiChu, NgaySinh, GioiTinh, PhongBanChucVu
    FROM tblTKB_GiaoVien
    WHERE Enable = 1
      AND (@Keyword = '' OR HoTen LIKE '%' + @Keyword + '%' OR MaGV LIKE '%' + @Keyword + '%')
      AND (@ChiThinhGiang = 0 OR LaThinhGiang = 1)
    ORDER BY HoTen
END
