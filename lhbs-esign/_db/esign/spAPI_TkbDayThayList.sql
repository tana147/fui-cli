CREATE PROCEDURE spAPI_TkbDayThayList
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL,
    @MaGV VARCHAR(15) = '',
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT dt.ID, dt.NgayApDung, k.MaLop, k.Buoi, k.Tiet, k.MaMon, m.TenMon,
           dt.MaGVVang, gv1.HoTen AS TenGVVang,
           dt.MaGVDayThay, gv2.HoTen AS TenGVDayThay,
           dt.LyDo, dt.GhiChu
    FROM tblTKB_DayThay dt
    INNER JOIN tblTKB_KetQuaXep k ON k.ID = dt.KetQuaXepID
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv1 ON gv1.MaGV = dt.MaGVVang
    LEFT JOIN tblTKB_GiaoVien gv2 ON gv2.MaGV = dt.MaGVDayThay
    WHERE dt.Enable = 1
      AND (@TuNgay IS NULL OR dt.NgayApDung >= @TuNgay)
      AND (@DenNgay IS NULL OR dt.NgayApDung <= @DenNgay)
      AND (@MaGV = '' OR dt.MaGVVang = @MaGV)
    ORDER BY dt.NgayApDung DESC, k.Buoi, k.Tiet;
END