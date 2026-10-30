CREATE PROCEDURE spAPI_TkbPhongHocList
    @Keyword    nvarchar(100),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT MaPhong, TenPhong, KieuPhong, MonHocChoPhep, SucChuaToiDa_TieuHoc, SucChuaToiDa_MamNon
    FROM tblTKB_PhongHoc
    WHERE Enable = 1
      AND (@Keyword = '' OR TenPhong LIKE '%' + @Keyword + '%' OR MaPhong LIKE '%' + @Keyword + '%')
    ORDER BY MaPhong
END
