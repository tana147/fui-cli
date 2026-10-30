CREATE PROCEDURE spAPI_TkbRoundThongKe
    @RunID INT,
    @Khoi VARCHAR(50) = '',
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (UI 4-Round): thong ke dung chung sau moi buoc (Round 1/2/4) — % tiet DA XEP THAT
    -- (khop dung 1 dong PCGD that, loai tru cac "don vi hien thi" nhu HOP/marker Cum tach khong phai
    -- tiet day that) tren tong so tiet CAN xep toan bo pham vi @Khoi/@HocKy/@TuanHienTai.
    DECLARE @TongSoTiet INT, @SoTietDaXep INT;

    ;WITH PCGDLoc AS (
        SELECT pc.*, l.Khoi,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1','TANN','SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    )
    SELECT @TongSoTiet = SUM(SoTietChuanTuan) FROM PCGDLoc WHERE MaMon NOT IN ('ENG1','TANN','SU') OR rn = 1;

    SELECT @SoTietDaXep = COUNT(*)
    FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID
      AND EXISTS (
          SELECT 1 FROM tblTKB_PhanCongGiangDay pc
          WHERE pc.Enable = 1 AND pc.MaLop = k.MaLop AND pc.MaMon = k.MaMon AND pc.MaGV = k.MaGV
      );

    -- GVDangXuLy/ViTriGV/TongSoGV (2026-09-12, theo de xuat nguoi dung "show ten nguoi ra moi lan
    -- Round 2 chay 1 GV") — cho UI biet dung dang xu ly GV nao, tranh cam giac "treo" khi % it doi.
    SELECT @RunID AS RunID, @TongSoTiet AS TongSoTiet, @SoTietDaXep AS SoTietDaXep,
           CAST(ROUND(100.0 * @SoTietDaXep / NULLIF(@TongSoTiet, 0), 1) AS DECIMAL(5,1)) AS PhanTramDaXep,
           (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID) AS SoNhomKhongXepDuoc,
           cal.TrangThai AS TrangThaiRunID,
           gv.HoTen AS TenGVDangXuLy, cal.ViTriGV, cal.TongSoGV
    FROM tblTKB_ChayAutoLog cal
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = cal.GVDangXuLy
    WHERE cal.RunID = @RunID;
END
