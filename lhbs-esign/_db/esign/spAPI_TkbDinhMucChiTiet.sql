CREATE PROCEDURE spAPI_TkbDinhMucChiTiet
    @RunID INT = NULL,
    @MaLop VARCHAR(10) = NULL,
    @MaGV VARCHAR(9) = NULL,
    @Khoi VARCHAR(50) = NULL,
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-15 (theo de xuat nguoi dung "xem dinh muc cua lop/tuan va cua GV khi click vao"):
    -- tra ve chi tiet PHAN CONG GIANG DAY (dinh muc that) cho 1 lop HOAC 1 GV cu the, kem so tiet
    -- DA XEP trong RunID hien tai (neu co) de doi chieu Con lai. Dung cho dialog "Xem dinh muc" o UI
    -- Round — bam vao ten lop hoac ten GV se goi SP nay voi dung 1 trong 2 tham so @MaLop/@MaGV.
    -- @Khoi (2026-09-16, theo de xuat nguoi dung "xem ca khoi thi moi lop cung phai co dinh muc de
    -- do" — khi UI hien luoi ca khoi (nhieu lop cung luc), goi 1 LAN duy nhat lay dinh muc CA KHOI
    -- thay vi N lan rieng tung lop, giam so API call. Ho tro nhieu khoi cach nhau dau phay (','), giong
    -- @Khoi cua spAPI_TkbChayAuto.
    SELECT
        pc.MaLop, pc.MaMon, mh.TenMon, pc.MaGV, gv.HoTen,
        pc.SoTietChuanTuan,
        ISNULL((
            SELECT COUNT(*) FROM tblTKB_KetQuaXep k
            WHERE @RunID IS NOT NULL AND k.RunID = @RunID
              AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV
        ), 0) AS SoTietDaXep
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_MonHoc mh ON mh.MaMon = pc.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = pc.MaGV
    WHERE pc.Enable = 1
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
      AND (@MaLop IS NULL OR pc.MaLop = @MaLop)
      AND (@MaGV IS NULL OR pc.MaGV = @MaGV)
      AND (@Khoi IS NULL OR @Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
    ORDER BY pc.MaLop, pc.MaMon;
END
