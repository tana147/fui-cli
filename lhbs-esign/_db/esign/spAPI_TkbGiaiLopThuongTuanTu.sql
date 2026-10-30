CREATE PROCEDURE spAPI_TkbGiaiLopThuongTuanTu
    @Khoi VARCHAR(50),
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecsPerLop INT = 60,
    @SoLopMoiLan INT = 5,
    @Nhom VARCHAR(4) = 'R4',
    @ChiMon VARCHAR(100) = NULL,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN (2026-09-18, mo rong CUNG nguyen tac da chung minh dung voi tiet doi/
    -- spAPI_TkbGiaiTietDoiTuanTu, ap dung cho Round 4/8 — sau khi phat hien qua RunID 1311: 63% phan du
    -- con lai la mon TOAN, rai deu tren 28 GV khac nhau, KHONG tap trung vao 1 vai GV (khac han pattern
    -- GV hep gio/fan-out cua tiet doi). Nguyen nhan that: mon thuong (TOAN/VAN...) canh tranh cho o
    -- LOP (nhieu mon/nhieu GV khac nhau cung tranh slot cua 1 LOP trong 1 lan CP-SAT gop toan @Khoi),
    -- KHONG PHAI o GV — nen don vi giai tuan tu dung phai la LOP (giai TOAN BO mon con lai cua 1 lop
    -- trong 1 lan goi rieng, khoa ngay, roi sang lop ke tiep), khong phai GV nhu tiet doi. TOAN (mon co
    -- khoi luong PCGD lon nhat — moi lop deu hoc) de bi "an" giua dam dong khi giai gop nhieu mon/nhieu
    -- lop cung luc, du KHONG GV nao thuc su qua tai.
    IF @MaxSecsPerLop IS NULL OR @MaxSecsPerLop < 10 SET @MaxSecsPerLop = 10;
    IF @MaxSecsPerLop > 180 SET @MaxSecsPerLop = 180;
    IF @SoLopMoiLan IS NULL OR @SoLopMoiLan < 1 SET @SoLopMoiLan = 1;

    IF @RunID IS NULL OR NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThaiCuoiCung, 0 AS SoLopConLai;
        RETURN;
    END

    DECLARE @DsLop TABLE (MaLop VARCHAR(10) PRIMARY KEY, SoTietCanXep INT, SoTietKhaDung INT, TyLeCang FLOAT, DaXuLy BIT NOT NULL DEFAULT 0);

    ;WITH PCLop AS (
        SELECT pc.MaLop, pc.SoTietChuanTuan,
            (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) AS SoTietDaXep
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@ChiMon IS NULL OR @ChiMon = '' OR pc.MaMon IN (SELECT value FROM STRING_SPLIT(@ChiMon, ',')))
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    ),
    LopCanXep AS (
        SELECT MaLop, SUM(SoTietChuanTuan - SoTietDaXep) AS SoTietCanXep
        FROM PCLop
        GROUP BY MaLop
        HAVING SUM(SoTietChuanTuan - SoTietDaXep) > 0
    ),
    -- SoTietKhaDung: 50 slot chuan/tuan (Thu2-6 x Sang/Chieu x 5 tiet) tru so slot LOP DA CO (bat ke
    -- mon gi — SH/HDTN1/cum tach/tiet doi da khoa deu tinh la "da chiem", KHONG can phan biet lien ke
    -- nhu tiet doi vi mon thuong khong doi hoi ke nhau).
    KhaDung AS (
        SELECT MaLop, 50 - COUNT(DISTINCT CONCAT(Thu, '-', Buoi, '-', Tiet)) AS SoTietKhaDung
        FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID
        GROUP BY MaLop
    )
    INSERT INTO @DsLop (MaLop, SoTietCanXep, SoTietKhaDung, TyLeCang)
    SELECT lc.MaLop, lc.SoTietCanXep, ISNULL(kd.SoTietKhaDung, 50),
           CAST(lc.SoTietCanXep AS FLOAT) / NULLIF(ISNULL(kd.SoTietKhaDung, 50), 0)
    FROM LopCanXep lc
    LEFT JOIN KhaDung kd ON kd.MaLop = lc.MaLop
    -- Bo lop DA xu ly trong RunID nay (du thanh cong hay khong): lop con phan du khong giai duoc van
    -- cang cao nhat hang doi, neu khong loai thi bi chon lai vo han va cac lop sau khong bao gio toi luot
    -- (cung loi da gap o Round 7 — xem tblTKB_Round2DaXuLy).
    -- @Nhom tach bang theo doi giua Round 4 va Round 8: neu dung chung, cac lop Round 4 da xu ly bi Round 8
    -- bo qua trong khi buoc XOA cua Round 8 da go cac dong Round 7 vua mo khoa -> mat tiet (RunID 1327).
    WHERE NOT EXISTS (SELECT 1 FROM tblTKB_LopTuanTuDaXuLy d WHERE @Nhom = 'R4' AND d.RunID = @RunID AND d.MaLop = lc.MaLop)
      AND NOT EXISTS (SELECT 1 FROM tblTKB_LopTuanTuDaXuLyR8 d8 WHERE @Nhom = 'R8' AND d8.RunID = @RunID AND d8.MaLop = lc.MaLop)
      AND NOT EXISTS (SELECT 1 FROM tblTKB_LopTuanTuDaXuLyMC dm WHERE @Nhom = 'MC' AND dm.RunID = @RunID AND dm.MaLop = lc.MaLop);

    DECLARE @TongSoLop INT = (SELECT COUNT(*) FROM @DsLop);
    DECLARE @ViTri INT = 1, @LopDangXu VARCHAR(10), @TrangThaiLop NVARCHAR(50), @WaitedSecs INT, @DaXuLyLanNay INT = 0;
    DECLARE @KhoiCuaLop VARCHAR(2);

    WHILE @ViTri <= @TongSoLop AND @DaXuLyLanNay < @SoLopMoiLan
    BEGIN
        -- Lop cang CANG (nhu cau con lai / cho trong con lai cao nhat) xu ly TRUOC — giong dung nguyen
        -- tac "GV cang hep xu ly truoc" cua tiet doi, chi doi don vi tu GV sang LOP.
        SELECT TOP 1 @LopDangXu = MaLop FROM @DsLop WHERE DaXuLy = 0
        ORDER BY CASE WHEN TyLeCang IS NULL THEN 999999 ELSE TyLeCang END DESC;

        IF @LopDangXu IS NULL BREAK;

        SELECT @KhoiCuaLop = Khoi FROM tblTKB_Lop WHERE MaLop = @LopDangXu;

        EXEC spAPI_TkbChayAuto @Khoi = @KhoiCuaLop, @HocKy = @HocKy, @MaxSecs = @MaxSecsPerLop,
             @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @ChiLop = @LopDangXu, @ChiMon = @ChiMon,
             @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

        SET @TrangThaiLop = N'DangChay'; SET @WaitedSecs = 0;
        WHILE @TrangThaiLop = N'DangChay' AND @WaitedSecs < (@MaxSecsPerLop + 60)
        BEGIN
            WAITFOR DELAY '00:00:01';
            SET @WaitedSecs = @WaitedSecs + 1;
            EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
            SELECT @TrangThaiLop = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
        END

        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT k.ID FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaLop = @LopDangXu AND kh.KetQuaXepID IS NULL;

        UPDATE @DsLop SET DaXuLy = 1 WHERE MaLop = @LopDangXu;
        IF @Nhom = 'R8' INSERT INTO tblTKB_LopTuanTuDaXuLyR8 (RunID, MaLop, ThoiGian) VALUES (@RunID, @LopDangXu, SYSUTCDATETIME());
        ELSE IF @Nhom = 'MC' INSERT INTO tblTKB_LopTuanTuDaXuLyMC (RunID, MaLop, ThoiGian) VALUES (@RunID, @LopDangXu, SYSUTCDATETIME());
        ELSE INSERT INTO tblTKB_LopTuanTuDaXuLy (RunID, MaLop, ThoiGian) VALUES (@RunID, @LopDangXu, SYSUTCDATETIME());
        SET @ViTri = @ViTri + 1;
        SET @DaXuLyLanNay = @DaXuLyLanNay + 1;
    END

    IF @ViTri <= @TongSoLop
    BEGIN
        SELECT @RunID AS RunID, N'ConTiepTuc' AS TrangThaiCuoiCung, @TongSoLop - @ViTri + 1 AS SoLopConLai;
        RETURN;
    END

    SELECT @RunID AS RunID, N'HoanTat' AS TrangThaiCuoiCung, 0 AS SoLopConLai;
END
