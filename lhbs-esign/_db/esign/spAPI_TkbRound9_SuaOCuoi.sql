CREATE PROCEDURE spAPI_TkbRound9_SuaOCuoi
    @RunID INT,
    @HocKy VARCHAR(4) = 'HK1',
    @KhoiLoc VARCHAR(50) = '01,02,03,04,05,06,07,08,09',
    @MaxSecsPerNhom INT = 90,
    @SoNhomMoiLan INT = 15,
    @SoLopXungDot INT = 4,
    @CaKhoiTieuHoc BIT = 1,
    @CaKhoiTatCa BIT = 0,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- @CaKhoiTatCa (2026-09-26): 1 = gop CA KHOI (moi khoi, ke ca 06-12) vao nhom nhu khoi tieu hoc — lop khoi 08 kin 39-40/40 o, GV chung nhieu lop
    -- nen phai giai chung ca khoi thay vi tung lop (giai tuan tu khong hoan doi duoc).
    -- MO TA NGAN: Round 9 — SUA "O CUOI". Sau Round 8, lop con thieu 1-2 tiet thuong do o trong DUY NHAT cua
    -- lop roi vao luc GV dang ban o lop khac (ket qua doi chung RunID 1327: 18 lop tieu hoc thieu TOAN, deu
    -- vay) — engine giai tung lop khoa lop ngay sau khi xep nen khong the hoan doi. Buoc nay: voi moi lop con
    -- thieu, gom NHOM = lop do + cac lop co GV (cua tiet thieu) dang ban dung o trong cua lop do (toi da 4
    -- lop), mo khoa cac dong mon thuong cua nhom, giai lai CA NHOM cung luc (spAPI_TkbChayAuto @ChiLop nhieu
    -- lop), roi CHI GIU neu nhom xep duoc NHIEU tiet hon; neu khong thi khoi phuc y nguyen tu ban chup
    -- (khong the lam te hon). Khong dong vao: SH, HDTN1, mon tiet doi/pattern (Round 3/5/6), GV thinh giang
    -- va GV co lich cam theo tuan (nhung dong nay giu nguyen lam rang buoc).
    IF @MaxSecsPerNhom IS NULL OR @MaxSecsPerNhom < 10 SET @MaxSecsPerNhom = 10;
    IF @MaxSecsPerNhom > 180 SET @MaxSecsPerNhom = 180;
    IF @SoNhomMoiLan IS NULL OR @SoNhomMoiLan < 1 SET @SoNhomMoiLan = 1;
    IF @SoLopXungDot IS NULL OR @SoLopXungDot < 1 SET @SoLopXungDot = 4;
    IF @SoLopXungDot > 10 SET @SoLopXungDot = 10;
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');

    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThaiCuoiCung;
        RETURN;
    END

    DECLARE @TuanHienTai INT;
    SELECT @TuanHienTai = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    DECLARE @DaThu INT = 0, @CaiThien INT = 0, @TietThem INT = 0;
    -- Chot nhom bi bo do tu lan goi truoc (phien bi cat, timeout...) truoc khi chon nhom moi.
    IF EXISTS (SELECT 1 FROM tblTKB_Round9Pending WHERE RunID = @RunID)
    BEGIN
        DECLARE @CT0 INT, @TT0 INT;
        EXEC spTkbRound9_ChotNhom @RunID = @RunID, @MaxChoGiay = 240, @CaiThien = @CT0 OUTPUT, @TietThem = @TT0 OUTPUT, @sys_UserID = @sys_UserID;
    END

    DECLARE @L VARCHAR(10), @TrangThai NVARCHAR(50), @Waited INT, @MaxIDTruoc INT;
    DECLARE @SoTruoc INT, @SoSau INT, @NhomStr VARCHAR(100), @KhoiNhom VARCHAR(50), @LopStr VARCHAR(100);
    DECLARE @NhomLop TABLE (MaLop VARCHAR(10) PRIMARY KEY);
    DECLARE @MissGV TABLE (MaGV VARCHAR(15) PRIMARY KEY);

    WHILE @DaThu < @SoNhomMoiLan
    BEGIN
        -- Chon lop con thieu nhieu nhat (chua thu trong RunID nay).
        SET @L = NULL;
        ;WITH PCLop AS (
            SELECT pc.MaLop, pc.SoTietChuanTuan -
                (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) AS Thieu
            FROM tblTKB_PhanCongGiangDay pc
            INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
            WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
              AND l.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiLoc, ','))
              AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
              AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
              AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        )
        SELECT TOP 1 @L = MaLop FROM PCLop
        WHERE NOT EXISTS (SELECT 1 FROM tblTKB_Round9DaXuLy d WHERE d.RunID = @RunID AND d.MaLop = PCLop.MaLop)
        GROUP BY MaLop HAVING SUM(CASE WHEN Thieu > 0 THEN Thieu ELSE 0 END) > 0
        ORDER BY SUM(CASE WHEN Thieu > 0 THEN Thieu ELSE 0 END) DESC, MaLop;

        IF @L IS NULL BREAK;

        -- GV cua cac tiet con thieu cua lop L.
        DELETE FROM @MissGV;
        INSERT INTO @MissGV (MaGV)
        SELECT DISTINCT pc.MaGV FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.MaLop = @L AND pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          AND (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) < pc.SoTietChuanTuan;

        -- Mo rong (RunID 1331: o trong cua 02B bi GVCN hop khoi HOP T6 Sang T1-2 chiem, tiet TOAN phai chuyen
        -- sang o khac va 1 tiet cua GV CHUYEN MON phai chuyen vao o hop): ngoai GV thieu tiet, tinh them MOI GV
        -- dang day lop L (tru dong HOP) — lop xung dot la lop ma BAT KY GV nao cua L dang ban dung o trong cua L.
        INSERT INTO @MissGV (MaGV)
        SELECT DISTINCT k.MaGV FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.MaLop = @L AND k.MaMon NOT IN ('SH', 'HDTN1', 'KHOAPHONG')
          AND NOT EXISTS (SELECT 1 FROM @MissGV m WHERE m.MaGV = k.MaGV);

        -- NHOM = L + toi da 4 lop ma cac GV tren dang ban dung o cac o TRONG cua L.
        DELETE FROM @NhomLop;
        INSERT INTO @NhomLop (MaLop) VALUES (@L);
        INSERT INTO @NhomLop (MaLop)
        SELECT TOP (@SoLopXungDot) k.MaLop
        FROM tblTKB_KetQuaXep k
        INNER JOIN tblTKB_Lop lm ON lm.MaLop = k.MaLop AND lm.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiLoc, ','))
        WHERE k.RunID = @RunID AND k.MaLop <> @L AND k.MaGV IN (SELECT MaGV FROM @MissGV)
          AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep kl WHERE kl.RunID = @RunID AND kl.MaLop = @L
                          AND kl.Thu = k.Thu AND kl.Buoi = k.Buoi AND kl.Tiet = k.Tiet)
        GROUP BY k.MaLop ORDER BY COUNT(*) DESC, k.MaLop;

        -- CA KHOI TIEU HOC (2026-09-25): cac lop cung khoi tieu hoc dung CHUNG GV chuyen (vd 1 GV AI/TA day 7 lop) nen chuoi hoan doi
        -- di qua ca khoi; nhom 5 lop theo 'GV ban o o trong' thuong bo sot lop lien quan. Lop thieu thuoc khoi 01-05 -> gop ca 7 lop cung khoi.
        IF (@CaKhoiTieuHoc = 1 OR @CaKhoiTatCa = 1) AND EXISTS (SELECT 1 FROM tblTKB_Lop lx WHERE lx.MaLop = @L AND (lx.Khoi < '06' OR @CaKhoiTatCa = 1))
        BEGIN
            INSERT INTO @NhomLop (MaLop)
            SELECT l2.MaLop FROM tblTKB_Lop l2
            WHERE l2.Enable = 1 AND LEN(l2.MaLop) = 3
              AND l2.Khoi = (SELECT Khoi FROM tblTKB_Lop WHERE MaLop = @L)
              AND NOT EXISTS (SELECT 1 FROM @NhomLop n WHERE n.MaLop = l2.MaLop);
        END

        SELECT @LopStr = STRING_AGG(MaLop, ',') FROM @NhomLop;
        SELECT @KhoiNhom = STRING_AGG(Khoi, ',') FROM (SELECT DISTINCT l.Khoi FROM tblTKB_Lop l INNER JOIN @NhomLop n ON n.MaLop = l.MaLop) x;

        -- Ban chup TOAN BO dong cua nhom + co "movable".
        IF OBJECT_ID('tempdb..#Snap') IS NOT NULL DROP TABLE #Snap;
        SELECT k.ID AS KID, k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon, k.MaGV, k.MaPhong, k.XoayTro,
               CAST(CASE WHEN kh.KetQuaXepID IS NULL THEN 0 ELSE 1 END AS BIT) AS DaKhoa,
               -- SUA 2026-09-25 (doi chieu RunID 1345 voi lich that): Round 9 khong the cuu vi 'movable' qua hep. Dong bo gio
               -- (tblTKB_CapMonDongBoGio) chi ton tai khoi 10-12 nen khoi 01-09 duoc phep doi: tiet doi (TA/AI/Boi/STEM/GDQP),
               -- mau TV, dong GV thinh giang / GV co lich cam tuan (lich cam van la rang buoc CUNG khi giai lai, va Round 9 van
               -- khoi phuc ban chup neu khong xep them duoc tiet nao). SH/HDTN1/KHOAPHONG va toan bo khoi 10-12 giu nhu cu.
               CAST(CASE WHEN k.MaMon IN ('SH', 'HDTN1', 'KHOAPHONG') THEN 0
                         WHEN lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_MonHoc mh WHERE mh.MaMon = k.MaMon AND mh.BatBuocXepDoi = 1) THEN 0
                         WHEN lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac mq WHERE mq.MaMon = k.MaMon AND mq.Enable = 1 AND mq.LoaiQuyTac LIKE '%_Pattern') THEN 0
                         WHEN lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_GiaoVien g WHERE g.MaGV = k.MaGV AND g.LaThinhGiang = 1) THEN 0
                         WHEN lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_GVCamTuyetDoi_Tuan c WHERE c.MaGV = k.MaGV AND c.Tuan = @TuanHienTai) THEN 0
                         ELSE 1 END AS BIT) AS Movable
        INTO #Snap
        FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_Lop lp ON lp.MaLop = k.MaLop
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaLop IN (SELECT MaLop FROM @NhomLop);

        SELECT @SoTruoc = COUNT(*) FROM #Snap WHERE MaMon <> 'KHOAPHONG';
        SELECT @MaxIDTruoc = ISNULL(MAX(ID), 0) FROM tblTKB_KetQuaXep;

        -- Luu ban chup BEN (2026-09-25) TRUOC khi xoa: neu phien bi cat giua chung, lan goi sau se chot nhom
        -- (spTkbRound9_ChotNhom) thay vi mat cac dong movable.
        DELETE FROM tblTKB_Round9Snap WHERE RunID = @RunID;
        DELETE FROM tblTKB_Round9Pending WHERE RunID = @RunID;
        INSERT INTO tblTKB_Round9Snap (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro, DaKhoa, Movable)
        SELECT @RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro, DaKhoa, Movable FROM #Snap;
        INSERT INTO tblTKB_Round9Pending (RunID, L, NhomLop, KhoiNhom, MaxIDTruoc, SoTruoc)
        VALUES (@RunID, @L, @LopStr, @KhoiNhom, @MaxIDTruoc, @SoTruoc);

        -- Mo khoa + xoa cac dong movable.
        DELETE kh FROM tblTKB_KetQuaXep_Khoa kh INNER JOIN #Snap s ON s.KID = kh.KetQuaXepID WHERE s.Movable = 1;
        DELETE k FROM tblTKB_KetQuaXep k INNER JOIN #Snap s ON s.KID = k.ID WHERE s.Movable = 1;

        -- WARM-START tu loi giai HIEN CO (2026-09-25): thu nghiem RunID 1345 cho thay nhom 9 lop giai lai TU CON SO 0
        -- luon te hon loi giai dang co (-11 tiet, ca 3 nhom bi khoi phuc). Tao RunID 'bong' (Enable=0) chua cac dong movable
        -- vua go, truyen @RunIDGoiY de CP-SAT bat dau tu loi giai dang co thay vi tu 0.
        DECLARE @MaxSecsNhom INT = @MaxSecsPerNhom;
        IF (@CaKhoiTieuHoc = 1 OR @CaKhoiTatCa = 1) AND EXISTS (SELECT 1 FROM tblTKB_Lop lx WHERE lx.MaLop = @L AND (lx.Khoi < '06' OR @CaKhoiTatCa = 1)) AND @MaxSecsNhom < 90 SET @MaxSecsNhom = 90;
        IF @CaKhoiTatCa = 1 AND @MaxSecsNhom < 150 SET @MaxSecsNhom = 150;
        DECLARE @RunIDBong INT;
        INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
        VALUES (SYSUTCDATETIME(), N'WS', 0, N'WarmStartSnapshot', @sys_UserID, @TuanHienTai, 0);
        SET @RunIDBong = SCOPE_IDENTITY();
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
        SELECT @RunIDBong, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro FROM #Snap WHERE Movable = 1 AND MaMon <> 'KHOAPHONG';

        EXEC spAPI_TkbChayAuto @Khoi = @KhoiNhom, @HocKy = @HocKy, @MaxSecs = @MaxSecsNhom,
             @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @RunIDGoiY = @RunIDBong, @ChiLop = @LopStr,
             @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

        DECLARE @CT INT, @TT INT;
        EXEC spTkbRound9_ChotNhom @RunID = @RunID, @MaxChoGiay = 300, @CaiThien = @CT OUTPUT, @TietThem = @TT OUTPUT, @sys_UserID = @sys_UserID;
        SET @CaiThien = @CaiThien + ISNULL(@CT, 0); SET @TietThem = @TietThem + ISNULL(@TT, 0);
        DELETE FROM tblTKB_KetQuaXep WHERE RunID = @RunIDBong;
        DELETE FROM tblTKB_ChayAutoLog WHERE RunID = @RunIDBong;

        SET @DaThu = @DaThu + 1;
    END

    SELECT @RunID AS RunID,
           CASE WHEN @DaThu >= @SoNhomMoiLan THEN N'ConTiepTuc' ELSE N'HoanTat' END AS TrangThaiCuoiCung,
           @DaThu AS SoNhomThuLanNay, @CaiThien AS SoNhomCaiThien, @TietThem AS SoTietThem;
END
