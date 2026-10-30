CREATE PROCEDURE spAPI_TkbPhanCongList
    @Khoi varchar(2),
    @Keyword nvarchar(100),
    @HocKy varchar(4) = 'HK1',
    @MaMon varchar(15) = '',
    @MaGV varchar(15) = '',
    @sys_UserID varchar(9)
AS
BEGIN
    SELECT pc.PhanCongID, pc.MaGV, gv.HoTen AS TenGV, gv.GhiChu AS ToGV, pc.MaLop, l.Khoi, pc.MaMon, m.TenMon, pc.SoTietChuanTuan, pc.HocKy,
        pc.TuanApDungTu, pc.TuanApDungDen, pc.ApDungTuanChan
    FROM tblTKB_PhanCongGiangDay pc
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = pc.MaGV
    LEFT JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = pc.MaMon
    WHERE pc.Enable = 1 AND (ISNULL(@Khoi, '') = '' OR l.Khoi = @Khoi) AND (ISNULL(@HocKy, '') = '' OR pc.HocKy = @HocKy)
      AND (ISNULL(@MaMon, '') = '' OR pc.MaMon = @MaMon)
      AND (ISNULL(@MaGV, '') = '' OR pc.MaGV = @MaGV)
      AND (ISNULL(@Keyword, '') = '' OR gv.HoTen LIKE '%' + @Keyword + '%' OR pc.MaLop LIKE '%' + @Keyword + '%' OR m.TenMon LIKE '%' + @Keyword + '%')
    ORDER BY pc.MaLop, m.TenMon
END