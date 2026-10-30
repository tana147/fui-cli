CREATE PROCEDURE spAPI_TkbRound3b_ThinhGiang
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecsPerGV INT = 30,
    @SoGVMoiLan INT = 1,
    @ChiCapNhat BIT = 0,
    @TrangThaiRa VARCHAR(12) = NULL OUTPUT,
    @SoGVConLaiRa INT = NULL OUTPUT,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN (2026-09-26, theo de xuat nguoi dung sau khi doi chung RunID 1359): xep TRUOC toan bo tiet (moi mon, moi khoi)
    -- cua GV THINH GIANG / GV it o cho phep theo tung GV mot, GV KHAN HIEM NHAT truoc, khoa ngay. Ly do: Round 4/8 xep theo LOP
    -- (khong theo GV) nen 4 lop cua 1 GV thinh giang (vd Yen Nhi day Dia 11B1/11C/11D/11E, chi ~15 o cho phep) lan luot lay o cua GV
    -- roi lop den sau (11C) het o -> thieu. Chay o dau Round 3 (SAU Round 2 cum tach, TRUOC tiet doi va lop thuong).
    -- Khan hiem = tong tiet con can / so o cho phep (50 tru o bao ban tuan). GV thuoc dien: LaThinhGiang = 1 HOAC o cho phep <= 30.
    -- Tra ket qua qua OUTPUT (@TrangThaiRa: 'ConTiepTuc' | 'HoanTat', @SoGVConLaiRa); @ChiCapNhat = 0 moi SELECT (dung khi goi truc tiep).
    IF @MaxSecsPerGV IS NULL OR @MaxSecsPerGV < 10 SET @MaxSecsPerGV = 10;
    IF @MaxSecsPerGV > 120 SET @MaxSecsPerGV = 120;
    IF @SoGVMoiLan IS NULL OR @SoGVMoiLan < 1 SET @SoGVMoiLan = 1;
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');

    IF @RunID IS NULL OR NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SET @TrangThaiRa = 'HoanTat'; SET @SoGVConLaiRa = 0;
        IF @ChiCapNhat = 0 SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThaiCuoiCung, 0 AS SoGVConLai;
        RETURN;
    END
    IF @TuanHienTai IS NULL SELECT @TuanHienTai = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    DECLARE @DsGV TABLE (MaGV VARCHAR(9) PRIMARY KEY, TongCan INT, OChoPhep INT, TyLeCang FLOAT, DaXuLy BIT DEFAULT 0);

    ;WITH Cam AS (
        SELECT c.MaGV, COUNT(DISTINCT CAST(c.Thu AS VARCHAR(2)) + b.B + CAST(t.T AS VARCHAR(2))) AS N
        FROM tblTKB_GVCamTuyetDoi_Tuan c
        CROSS APPLY (VALUES ('Sang'), ('Chieu')) b(B)
        CROSS APPLY (VALUES (1), (2), (3), (4), (5)) t(T)
        WHERE c.Tuan = @TuanHienTai AND (ISNULL(c.Buoi, '') = '' OR c.Buoi = b.B) AND (c.Tiet IS NULL OR c.Tiet = t.T)
        GROUP BY c.MaGV
    ),
    Can AS (
        SELECT pc.MaGV, SUM(CASE WHEN pc.SoTietChuanTuan - ISNULL(x.Xep, 0) > 0 THEN pc.SoTietChuanTuan - ISNULL(x.Xep, 0) ELSE 0 END) AS TongCan
        FROM (
            SELECT MaLop, MaMon, MaGV, SUM(SoTietChuanTuan) AS SoTietChuanTuan
            FROM tblTKB_PhanCongGiangDay
            WHERE Enable = 1 AND HocKy = @HocKy AND MaGV IS NOT NULL
              AND (@TuanHienTai IS NULL OR TuanApDungTu IS NULL OR @TuanHienTai >= TuanApDungTu)
              AND (@TuanHienTai IS NULL OR TuanApDungDen IS NULL OR @TuanHienTai <= TuanApDungDen)
              AND (@TuanHienTai IS NULL OR ApDungTuanChan IS NULL OR ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
              AND MaMon NOT IN ('SH', 'HDTN1')
            GROUP BY MaLop, MaMon, MaGV
        ) pc
        LEFT JOIN (
            SELECT MaLop, MaMon, MaGV, COUNT(*) AS Xep FROM tblTKB_KetQuaXep WHERE RunID = @RunID GROUP BY MaLop, MaMon, MaGV
        ) x ON x.MaLop = pc.MaLop AND x.MaMon = pc.MaMon AND x.MaGV = pc.MaGV
        GROUP BY pc.MaGV
    )
    INSERT INTO @DsGV (MaGV, TongCan, OChoPhep, TyLeCang)
    SELECT c.MaGV, c.TongCan, 50 - ISNULL(cm.N, 0),
           CAST(c.TongCan AS FLOAT) / NULLIF(50 - ISNULL(cm.N, 0), 0)
    FROM Can c
    INNER JOIN tblTKB_GiaoVien g ON g.MaGV = c.MaGV
    LEFT JOIN Cam cm ON cm.MaGV = c.MaGV
    WHERE c.TongCan > 0
      AND (g.LaThinhGiang = 1 OR 50 - ISNULL(cm.N, 0) <= 30)
      AND NOT EXISTS (SELECT 1 FROM tblTKB_TietDoiTuanTuDaXuLy d WHERE d.RunID = @RunID AND d.MaGV = c.MaGV AND d.Khoi = 'TG');

    DECLARE @TongSoGV INT = (SELECT COUNT(*) FROM @DsGV);
    DECLARE @GVDangXu VARCHAR(9), @TrangThaiGV NVARCHAR(50), @WaitedSecs INT, @DaXuLyLanNay INT = 0, @DaXongTrongVong INT = 0;

    WHILE @DaXuLyLanNay < @SoGVMoiLan
    BEGIN
        SET @GVDangXu = NULL;
        SELECT TOP 1 @GVDangXu = MaGV FROM @DsGV WHERE DaXuLy = 0
        ORDER BY CASE WHEN TyLeCang IS NULL THEN 999999 ELSE TyLeCang END DESC, TongCan DESC;
        IF @GVDangXu IS NULL BREAK;

        -- Giai TOAN BO tiet con thieu cua GV nay o MOI khoi (@Khoi = ''), moi mon (khong @ChiMonDoi).
        EXEC spAPI_TkbChayAuto @Khoi = '', @HocKy = @HocKy, @MaxSecs = @MaxSecsPerGV,
             @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @ChiGV = @GVDangXu,
             @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

        SET @TrangThaiGV = N'DangChay'; SET @WaitedSecs = 0;
        WHILE @TrangThaiGV = N'DangChay' AND @WaitedSecs < (@MaxSecsPerGV + 60)
        BEGIN
            WAITFOR DELAY '00:00:01';
            SET @WaitedSecs = @WaitedSecs + 1;
            EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
            SELECT @TrangThaiGV = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
        END

        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT k.ID FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu AND kh.KetQuaXepID IS NULL;

        UPDATE @DsGV SET DaXuLy = 1 WHERE MaGV = @GVDangXu;
        INSERT INTO tblTKB_TietDoiTuanTuDaXuLy (RunID, MaGV, Khoi, ThoiGian) VALUES (@RunID, @GVDangXu, 'TG', SYSUTCDATETIME());
        SET @DaXuLyLanNay = @DaXuLyLanNay + 1;
    END

    SET @SoGVConLaiRa = (SELECT COUNT(*) FROM @DsGV WHERE DaXuLy = 0);
    SET @TrangThaiRa = CASE WHEN @SoGVConLaiRa > 0 THEN 'ConTiepTuc' ELSE 'HoanTat' END;
    IF @ChiCapNhat = 0
        SELECT @RunID AS RunID, CAST(@TrangThaiRa AS NVARCHAR(20)) AS TrangThaiCuoiCung, @SoGVConLaiRa AS SoGVConLai, 0 AS SoGVKhongDuCho;
END
