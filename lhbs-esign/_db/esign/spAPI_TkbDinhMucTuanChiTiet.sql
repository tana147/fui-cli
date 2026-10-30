CREATE PROCEDURE spAPI_TkbDinhMucTuanChiTiet
    @MaMon      varchar(15),
    @Khoi       varchar(2),
    @Tuan       int,
    @HocKy      varchar(4),
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT pc.PhanCongID, pc.MaLop, pc.MaGV, gv.HoTen, pc.SoTietChuanTuan
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = pc.MaGV
    WHERE l.Khoi = @Khoi AND l.Enable = 1
      AND pc.MaMon = @MaMon AND pc.HocKy = @HocKy AND pc.Enable = 1
      AND (pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu)
      AND (pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
      AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
    ORDER BY pc.MaLop
END
