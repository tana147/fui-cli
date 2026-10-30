CREATE PROCEDURE spAPI_StemPhanCongList
    @Khoi       varchar(2),
    @TuTuan     int,
    @DenTuan    int,
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT s.StemPhanCongID, s.ThuTuTuan, s.Khoi, s.MaLop, s.MonPhuTrach, s.ChuDe, s.TenGV, s.MaGV, s.CreateTime,
        t.NgayBatDau, t.NgayKetThuc, t.TenTuan
    FROM tblTKB_StemPhanCong s
    LEFT JOIN tblTKB_Tuan t ON t.TuanTrongNam = s.ThuTuTuan
    WHERE s.Enable = 1
      AND (@Khoi = '' OR s.Khoi = @Khoi)
      AND s.ThuTuTuan BETWEEN @TuTuan AND @DenTuan
    ORDER BY s.ThuTuTuan, s.Khoi, s.MaLop
END
