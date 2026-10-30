CREATE PROCEDURE spAPI_TkbRound10_HoanDoi
    @RunID INT,
    @HocKy VARCHAR(4) = 'HK1',
    @KhoiLoc VARCHAR(50) = '01,02,03,04,05,06,07,08,09,10,11,12',
    @MaxSecsPerNhom INT = 90,
    @SoNhomMoiLan INT = 15,
    @SoLopXungDot INT = 4,
    @CaKhoiTieuHoc BIT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN (2026-09-26): Round 10 — HOAN DOI THEO CHUOI (round cuoi, tong quat). Voi moi lop con thieu tiet (l, mon, GV g):
    -- M1 = cac tiet cua lop l dang nam o o ma g RANH (o duy nhat g co the day, nhung lop dang ban); M2 = cac tiet cua GV cua M1 (o lop khac)
    -- nam o o TRONG cua lop l (cho de M1 chuyen sang). CHI mo (xoa) M1 + M2, giai lai NHOM NHO nay bang solver that (spAPI_TkbChayAuto @ChiLop +
    -- warm-start), nen moi luat cung cua solver van ap dung; chi GIU neu nhom xep duoc NHIEU tiet hon, neu khong khoi phuc y nguyen tu ban chup.
    -- Khac Round 9 (mo ca dong cua nhom lop, giai tu 0 that bai) o cho vung mo rat nho (~5-15 dong) nen solver toi uu duoc.
    -- Danh dau da thu: MaLop = '~' + lop trong tblTKB_Round9DaXuLy. Dung chung ban chup ben/ChotNhom voi Round 9.
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
    DECLARE @MissGVThieu TABLE (MaGV VARCHAR(15) PRIMARY KEY);

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
        WHERE NOT EXISTS (SELECT 1 FROM tblTKB_Round9DaXuLy d WHERE d.RunID = @RunID AND d.MaLop = '~' + PCLop.MaLop)
        GROUP BY MaLop HAVING SUM(CASE WHEN Thieu > 0 THEN Thieu ELSE 0 END) > 0
        ORDER BY SUM(CASE WHEN Thieu > 0 THEN Thieu ELSE 0 END) DESC, MaLop;

        IF @L IS NULL BREAK;

        -- GV cua cac tiet con thieu cua lop L (chi GV THIEU).
        DELETE FROM @MissGVThieu;
        INSERT INTO @MissGVThieu (MaGV)
        SELECT DISTINCT pc.MaGV FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.MaLop = @L AND pc.Enable = 1 AND pc.HocKy = @HocKy AND pc.MaGV IS NOT NULL
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          AND (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) < pc.SoTietChuanTuan;

        -- GV cua cac tiet con thieu cua lop L.
        DELETE FROM @MissGV;
        INSERT INTO @MissGV (MaGV)
        SELECT DISTINCT pc.MaGV FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.MaLop = @L AND pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          AND (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) < pc.SoTietChuanTuan;

        -- ===== CHUOI HOAN DOI: M1 / M2 =====
        IF OBJECT_ID('tempdb..#M') IS NOT NULL DROP TABLE #M;
        CREATE TABLE #M (KID INT PRIMARY KEY, MaLop VARCHAR(10));
        IF OBJECT_ID('tempdb..#GFree') IS NOT NULL DROP TABLE #GFree;
        CREATE TABLE #GFree (MaGV VARCHAR(15), Thu INT, Buoi VARCHAR(10), Tiet INT);
        CREATE INDEX IX_GFree ON #GFree (MaGV, Thu, Buoi, Tiet);

        ;WITH Sl AS (
            SELECT th.Thu, bu.Buoi, ti.Tiet FROM (VALUES(2),(3),(4),(5),(6)) th(Thu)
            CROSS JOIN (VALUES('Sang'),('Chieu')) bu(Buoi) CROSS JOIN (VALUES(1),(2),(3),(4),(5)) ti(Tiet)
        ),
        CamG AS (
            SELECT g.MaGV, g.Thu, x.Buoi, y.Tiet
            FROM tblTKB_GVCamTuyetDoi_Tuan g
            CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) v(Buoi) WHERE ISNULL(g.Buoi, '') = '' OR g.Buoi = v.Buoi) x
            CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) w(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = w.Tiet) y
            WHERE g.Tuan = @TuanHienTai
        )
        INSERT INTO #GFree (MaGV, Thu, Buoi, Tiet)
        SELECT mg.MaGV, s.Thu, s.Buoi, s.Tiet FROM @MissGVThieu mg CROSS JOIN Sl s
        WHERE NOT EXISTS (SELECT 1 FROM CamG c WHERE c.MaGV = mg.MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet)
          AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep kg WHERE kg.RunID = @RunID AND kg.MaGV = mg.MaGV AND kg.Thu = s.Thu AND kg.Buoi = s.Buoi AND kg.Tiet = s.Tiet);

        -- M1: tiet cua lop L o o GV thieu tiet dang RANH.
        INSERT INTO #M (KID, MaLop)
        SELECT k.ID, k.MaLop FROM tblTKB_KetQuaXep k
        INNER JOIN #GFree f ON f.Thu = k.Thu AND f.Buoi = k.Buoi AND f.Tiet = k.Tiet
        WHERE k.RunID = @RunID AND k.MaLop = @L AND k.MaMon NOT IN ('SH', 'HDTN1', 'KHOAPHONG', 'HOP')
        GROUP BY k.ID, k.MaLop;

        -- O ton tai cua tung khoi (Khoi, Thu, Buoi, Tiet) — 1 o cua lop X 'trong' neu o do ton tai o khoi cua X ma X chua co dong.
        IF OBJECT_ID('tempdb..#Exist') IS NOT NULL DROP TABLE #Exist;
        SELECT DISTINCT lk.Khoi, kx.Thu, kx.Buoi, kx.Tiet INTO #Exist
        FROM tblTKB_KetQuaXep kx INNER JOIN tblTKB_Lop lk ON lk.MaLop = kx.MaLop
        WHERE kx.RunID = @RunID AND LEN(kx.MaLop) <= 4;

        -- M2..M4 (chuoi): tiet r (thuoc lop lr) phai chuyen sang 1 o trong cua lr; GV cua r phai ranh o do, neu khong tiet r' cua chinh GV do
        -- (o lop khac) nam o o trong cua lr bi day di. Lap toi da 3 buoc, moi buoc lay cac r' moi.
        IF OBJECT_ID('tempdb..#F') IS NOT NULL DROP TABLE #F;
        CREATE TABLE #F (KID INT PRIMARY KEY);
        INSERT INTO #F (KID) SELECT KID FROM #M;
        DECLARE @Buoc INT = 0, @SoMoi INT = 1;
        WHILE @Buoc < 3 AND @SoMoi > 0
        BEGIN
            IF OBJECT_ID('tempdb..#F2') IS NOT NULL DROP TABLE #F2;
            SELECT k2.ID AS KID, k2.MaLop INTO #F2
            FROM tblTKB_KetQuaXep kf
            INNER JOIN #F f ON f.KID = kf.ID
            INNER JOIN tblTKB_Lop lf ON lf.MaLop = kf.MaLop
            INNER JOIN tblTKB_KetQuaXep k2 ON k2.RunID = @RunID AND k2.MaGV = kf.MaGV AND k2.MaLop <> kf.MaLop AND LEN(k2.MaLop) <= 4
                 AND k2.MaMon NOT IN ('SH', 'HDTN1', 'KHOAPHONG', 'HOP')
            WHERE kf.RunID = @RunID
              AND EXISTS (SELECT 1 FROM #Exist e WHERE e.Khoi = lf.Khoi AND e.Thu = k2.Thu AND e.Buoi = k2.Buoi AND e.Tiet = k2.Tiet)
              AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep kl WHERE kl.RunID = @RunID AND kl.MaLop = kf.MaLop AND kl.Thu = k2.Thu AND kl.Buoi = k2.Buoi AND kl.Tiet = k2.Tiet)
              AND NOT EXISTS (SELECT 1 FROM #M mx WHERE mx.KID = k2.ID)
            GROUP BY k2.ID, k2.MaLop;
            SELECT @SoMoi = COUNT(*) FROM #F2;
            INSERT INTO #M (KID, MaLop) SELECT KID, MaLop FROM #F2;
            DELETE FROM #F; INSERT INTO #F (KID) SELECT KID FROM #F2;
            SET @Buoc = @Buoc + 1;
        END

        -- Nua con lai cua tiet doi (cung lop/mon/GV/buoi, tiet lien ke).
        INSERT INTO #M (KID, MaLop)
        SELECT DISTINCT kp.ID, kp.MaLop FROM tblTKB_KetQuaXep kp
        INNER JOIN tblTKB_KetQuaXep ks ON ks.RunID = kp.RunID AND ks.MaLop = kp.MaLop AND ks.MaMon = kp.MaMon AND ks.MaGV = kp.MaGV
             AND ks.Thu = kp.Thu AND ks.Buoi = kp.Buoi AND ABS(ks.Tiet - kp.Tiet) = 1
        INNER JOIN #M ms ON ms.KID = ks.ID
        WHERE kp.RunID = @RunID AND kp.MaMon IN ('TAVN', 'TANN', 'AI', 'STEM', 'GDQP', 'ENG1', 'ENG2', 'BOI')
          AND NOT EXISTS (SELECT 1 FROM #M mx WHERE mx.KID = kp.ID);

        -- Khong dong: GV khong that (cum tach...), khoi 10-12 co tiet doi/pattern bat buoc.
        DELETE m FROM #M m INNER JOIN tblTKB_KetQuaXep k ON k.ID = m.KID INNER JOIN tblTKB_Lop lp ON lp.MaLop = k.MaLop
        WHERE NOT EXISTS (SELECT 1 FROM tblTKB_GiaoVien gg WHERE gg.MaGV = k.MaGV)
           OR (lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_MonHoc mh WHERE mh.MaMon = k.MaMon AND mh.BatBuocXepDoi = 1))
           OR (lp.Khoi >= '10' AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac mq WHERE mq.MaMon = k.MaMon AND mq.Enable = 1 AND mq.LoaiQuyTac LIKE '%_Pattern'));

        -- NHOM = L + toi da 7 lop khac co dong trong M (nhieu dong nhat truoc).
        DELETE FROM @NhomLop;
        INSERT INTO @NhomLop (MaLop) VALUES (@L);
        INSERT INTO @NhomLop (MaLop)
        SELECT TOP (7) m.MaLop FROM #M m WHERE m.MaLop <> @L GROUP BY m.MaLop ORDER BY COUNT(*) DESC, m.MaLop;
        DELETE m FROM #M m WHERE NOT EXISTS (SELECT 1 FROM @NhomLop n WHERE n.MaLop = m.MaLop);

        SELECT @LopStr = (SELECT STRING_AGG(MaLop, ',') FROM @NhomLop);
        SELECT @KhoiNhom = (SELECT STRING_AGG(Khoi, ',') FROM (SELECT DISTINCT l.Khoi FROM tblTKB_Lop l INNER JOIN @NhomLop n ON n.MaLop = l.MaLop) x);

        -- Ban chup TOAN BO dong cua nhom + co "movable".
        IF OBJECT_ID('tempdb..#Snap') IS NOT NULL DROP TABLE #Snap;
        SELECT k.ID AS KID, k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon, k.MaGV, k.MaPhong, k.XoayTro,
               CAST(CASE WHEN kh.KetQuaXepID IS NULL THEN 0 ELSE 1 END AS BIT) AS DaKhoa,
               CAST(CASE WHEN EXISTS (SELECT 1 FROM #M mm WHERE mm.KID = k.ID) THEN 1 ELSE 0 END AS BIT) AS Movable
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
        VALUES (@RunID, '~' + @L, @LopStr, @KhoiNhom, @MaxIDTruoc, @SoTruoc);

        -- Mo khoa + xoa cac dong movable.
        DELETE kh FROM tblTKB_KetQuaXep_Khoa kh INNER JOIN #Snap s ON s.KID = kh.KetQuaXepID WHERE s.Movable = 1;
        DELETE k FROM tblTKB_KetQuaXep k INNER JOIN #Snap s ON s.KID = k.ID WHERE s.Movable = 1;

        -- WARM-START tu loi giai HIEN CO (2026-09-25): thu nghiem RunID 1345 cho thay nhom 9 lop giai lai TU CON SO 0
        -- luon te hon loi giai dang co (-11 tiet, ca 3 nhom bi khoi phuc). Tao RunID 'bong' (Enable=0) chua cac dong movable
        -- vua go, truyen @RunIDGoiY de CP-SAT bat dau tu loi giai dang co thay vi tu 0.
        DECLARE @MaxSecsNhom INT = @MaxSecsPerNhom;
        IF @CaKhoiTieuHoc = 1 AND EXISTS (SELECT 1 FROM tblTKB_Lop lx WHERE lx.MaLop = @L AND lx.Khoi < '06') AND @MaxSecsNhom < 90 SET @MaxSecsNhom = 90;
        DECLARE @RunIDBong INT;
        INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
        VALUES (SYSUTCDATETIME(), N'WS', 0, N'WarmStartSnapshot', @sys_UserID, @TuanHienTai, 0);
        SET @RunIDBong = SCOPE_IDENTITY();
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
        SELECT @RunIDBong, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro FROM #Snap WHERE Movable = 1 AND MaMon <> 'KHOAPHONG';

        DECLARE @ChiLopArg VARCHAR(100) = CASE WHEN @LopStr = '*' THEN NULL ELSE @LopStr END;
        EXEC spAPI_TkbChayAuto @Khoi = @KhoiNhom, @HocKy = @HocKy, @MaxSecs = @MaxSecsNhom,
             @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @RunIDGoiY = @RunIDBong, @ChiLop = @ChiLopArg,
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
