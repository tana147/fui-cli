CREATE PROCEDURE spTkbVaCucBo_BatDau
    @RunID INT,
    @Vong TINYINT,
    @Tuan INT,
    @HocKy VARCHAR(4),
    @MaxSecs INT,
    @sys_UserID VARCHAR(9),
    @DaBatDau BIT OUTPUT
AS
BEGIN
    -- 2026-10-10 (giai doan 2 "va doi cho cuc bo", thi nghiem RunID 1567/1563): khoi dong 1 vong va cho lan chay @RunID.
    -- Vung theo vong (luon kem tron cum tach + lop TG):
    --   vong 1: lop con thieu + ca khoi cua chung + moi lop GV thieu tiet dang day
    --   vong 2: + cac lop dang giu GV/phong ma lop thieu can, tai cac o trong cua lop thieu (cach nguoi xep tay)
    --   vong 3: + ca khoi cua cac lop chan do
    -- Luu ban sao vung (de khoi phuc), go tiet cua vung (giu SH/HDTN1/HOP), giai lai co NEO tung tiet vao cho cu (phat 60 —
    -- thi nghiem: neo 200 thi solver chon bo tiet; chi goi y thi xao 77% tiet; neo 30-60 xep du, doi 6-12%).
    -- Chi dung noi bo (spAPI_TkbChayNhanh buoc 7-8), khong goi tu tAPI.
    SET NOCOUNT ON;
    SET @DaBatDau = 0;
    DECLARE @S TABLE (MaLop VARCHAR(15) PRIMARY KEY);
    DECLARE @Thieu TABLE (MaLop VARCHAR(15), MaGV VARCHAR(12));

    ;WITH Can AS (
        SELECT pc.MaLop, pc.MaMon, pc.MaGV, SUM(pc.SoTietChuanTuan) AS Can
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND pc.SoTietChuanTuan > 0 AND pc.MaLop NOT LIKE '26%'
          AND (pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu) AND (pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
          AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon, pc.MaGV
    )
    INSERT @Thieu
    SELECT c.MaLop, c.MaGV FROM Can c
    LEFT JOIN (SELECT MaLop, MaMon, MaGV, COUNT(*) AS Xep FROM tblTKB_KetQuaXep WHERE RunID = @RunID GROUP BY MaLop, MaMon, MaGV) x
           ON x.MaLop = c.MaLop AND x.MaMon = c.MaMon AND x.MaGV = c.MaGV
    WHERE ISNULL(x.Xep, 0) < c.Can AND c.MaMon NOT IN ('BTHT', 'SH');
    IF NOT EXISTS (SELECT 1 FROM @Thieu) RETURN;

    -- Phan cong hieu luc tuan (de tim lop GV dang day)
    SELECT DISTINCT pc.MaLop, pc.MaGV INTO #PC
    FROM tblTKB_PhanCongGiangDay pc
    WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND pc.SoTietChuanTuan > 0 AND pc.MaLop NOT LIKE '26%'
      AND (pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu) AND (pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
      AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END);

    -- Vong 1..3 (2026-10-14, gioi han vung: RunID 1622 tuan 13 vung 123 lop/vong, 50 phut, khong vua them tiet nao).
    -- Moi lop co do uu tien: 1 = lop thieu, 2 = lop GV thieu dang day, 3 = lop chan GV/phong tai o trong (vong >= 2),
    -- 4 = ca khoi cua lop thieu (vong 3). Vung = toi da @ToiDa lop uu tien cao nhat (truoc khi tron TG/cum tach).
    DECLARE @ToiDa INT = 60;
    DECLARE @U TABLE (MaLop VARCHAR(15) PRIMARY KEY, UuTien TINYINT);
    INSERT @U SELECT DISTINCT MaLop, 1 FROM @Thieu;
    INSERT @U SELECT DISTINCT p.MaLop, 2 FROM #PC p WHERE p.MaGV IN (SELECT MaGV FROM @Thieu) AND NOT EXISTS (SELECT 1 FROM @U u WHERE u.MaLop = p.MaLop);
    INSERT @S SELECT MaLop FROM @U;

    -- Vong 2 (2026-10-10, doi chieu lich tay RunID 1589 05D): "AI DANG GIU THU MINH CAN" — cac lop dang dung GV hoac PHONG cua lop
    -- thieu dung tai cac o trong cua lop thieu (vd 07H giu phong AN2 cua 05F luc GVCN khoi 5 hop).
    IF @Vong >= 2
    BEGIN
        DECLARE @Chan TABLE (MaLop VARCHAR(15) PRIMARY KEY);
        ;WITH LopThieu AS (SELECT DISTINCT t.MaLop, l.Khoi FROM @Thieu t INNER JOIN tblTKB_Lop l ON l.MaLop = t.MaLop),
        Khung AS (
            SELECT lt.MaLop, d.Thu, b.Buoi, x.Tiet FROM LopThieu lt
            CROSS JOIN (VALUES(2),(3),(4),(5),(6)) d(Thu) CROSS JOIN (VALUES('Sang'),('Chieu')) b(Buoi) CROSS JOIN (VALUES(1),(2),(3),(4),(5)) x(Tiet)
            WHERE x.Tiet <= 4 OR (b.Buoi = 'Sang' AND lt.Khoi >= '06')
        ),
        Trong AS (
            SELECT k.* FROM Khung k
            WHERE NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep q WHERE q.RunID = @RunID AND q.MaLop = k.MaLop AND q.Thu = k.Thu AND q.Buoi = k.Buoi AND q.Tiet = k.Tiet)
              AND NOT EXISTS (SELECT 1 FROM tblTKB_NgayNghi_Tuan n INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
                              WHERE n.Tuan = @Tuan AND n.Thu = k.Thu AND (ISNULL(n.Buoi, '') = '' OR n.Buoi = k.Buoi) AND (n.Tiet IS NULL OR n.Tiet = k.Tiet)
                                AND ((n.PhamVi = 'LOP' AND n.MaLop = k.MaLop) OR (n.PhamVi = 'KHOI' AND n.Khoi = l.Khoi) OR n.PhamVi = 'TRUONG'))
        ),
        GioTrong AS (SELECT DISTINCT Thu, Buoi, Tiet FROM Trong),
        CanGV AS (SELECT DISTINCT MaGV FROM @Thieu),
        CanPhong AS (
            SELECT DISTINCT f.MaPhong FROM tblTKB_PhongLopMon f WHERE f.Enable = 1 AND f.MaLop IN (SELECT MaLop FROM @Thieu)
            UNION SELECT DISTINCT pg.MaPhong FROM CanGV g INNER JOIN tblTKB_PhongGiaoVien pg ON pg.MaGV = g.MaGV AND pg.Enable = 1
        )
        INSERT @Chan
        SELECT DISTINCT q.MaLop FROM tblTKB_KetQuaXep q
        INNER JOIN GioTrong t ON t.Thu = q.Thu AND t.Buoi = q.Buoi AND t.Tiet = q.Tiet
        WHERE q.RunID = @RunID AND q.MaLop <> 'HOP' AND q.MaLop NOT LIKE '26%'
          AND NOT EXISTS (SELECT 1 FROM @U u WHERE u.MaLop = q.MaLop)
          AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = q.MaMon)
          AND (q.MaGV IN (SELECT MaGV FROM CanGV) OR q.MaPhong IN (SELECT MaPhong FROM CanPhong));
        INSERT @U SELECT MaLop, 3 FROM @Chan;
        IF @Vong >= 3
            INSERT @U SELECT DISTINCT l.MaLop, 4 FROM tblTKB_Lop l
                WHERE l.Enable = 1 AND l.MaLop NOT LIKE '26%' AND l.Khoi IN (SELECT l2.Khoi FROM tblTKB_Lop l2 WHERE l2.MaLop IN (SELECT MaLop FROM @Thieu))
                  AND NOT EXISTS (SELECT 1 FROM @U u WHERE u.MaLop = l.MaLop);
        DELETE @S;
        INSERT @S SELECT TOP (@ToiDa) MaLop FROM @U ORDER BY UuTien, MaLop;
    END
    ELSE
    BEGIN
        DELETE @S;
        INSERT @S SELECT TOP (@ToiDa) MaLop FROM @U ORDER BY UuTien, MaLop;
    END

    -- Lop TG theo lop goc; tron cum tach (lap 3 lan de bao dong bac cau: 11A -> 11A-CD -> 11A1 -> 11-AV ...)
    INSERT @S SELECT t.MaLop FROM tblTKB_Lop t WHERE t.Enable = 1 AND t.MaLop LIKE '%TG' AND LEFT(t.MaLop, 3) IN (SELECT MaLop FROM @S)
        AND NOT EXISTS (SELECT 1 FROM @S s WHERE s.MaLop = t.MaLop);
    DECLARE @i INT = 0;
    WHILE @i < 3
    BEGIN
        ;WITH CumCham AS (
            SELECT DISTINCT c.ID FROM tblTKB_CumTach c
            WHERE c.Enable = 1 AND (EXISTS (SELECT 1 FROM tblTKB_CumTach_LopNguon n WHERE n.CumTachID = c.ID AND n.MaLop IN (SELECT MaLop FROM @S))
                                 OR EXISTS (SELECT 1 FROM tblTKB_CumTach_NhomCon n WHERE n.CumTachID = c.ID AND n.MaLop IN (SELECT MaLop FROM @S)))
        ), Them AS (
            SELECT n.MaLop FROM tblTKB_CumTach_LopNguon n WHERE n.CumTachID IN (SELECT ID FROM CumCham)
            UNION SELECT n.MaLop FROM tblTKB_CumTach_NhomCon n WHERE n.CumTachID IN (SELECT ID FROM CumCham)
        )
        INSERT @S SELECT MaLop FROM Them WHERE NOT EXISTS (SELECT 1 FROM @S s WHERE s.MaLop = Them.MaLop);
        SET @i += 1;
    END

    DECLARE @VaLop VARCHAR(2000) = (SELECT STRING_AGG(CAST(MaLop AS VARCHAR(MAX)), ',') FROM @S);
    IF @VaLop IS NULL OR LEN(@VaLop) > 1000 RETURN;   -- @ChiLop cua spAPI_TkbChayAuto la VARCHAR(1000)

    -- Ban sao vung (RunID that — FK; su co RunID 1503) + chot an toan so dong
    DECLARE @BanSao INT, @SoGoc INT, @SoSao INT, @VaTruoc INT;
    INSERT INTO tblTKB_ChayAutoLog (Khoi, MaxSecs, TrangThai, NguoiChay, SoNhuCau, TuanHienTai)
    VALUES ('VA', 0, N'BanSaoVa', @sys_UserID, 0, @Tuan);
    SET @BanSao = SCOPE_IDENTITY();
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT @BanSao, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro
    FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop IN (SELECT MaLop FROM @S);
    SELECT @SoGoc = COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop IN (SELECT MaLop FROM @S);
    SELECT @SoSao = COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @BanSao;
    IF @BanSao IS NULL OR @SoSao <> @SoGoc OR @SoGoc = 0
    BEGIN
        DELETE FROM tblTKB_KetQuaXep WHERE RunID = @BanSao;
        RETURN;
    END
    -- So tiet THAT cua vung truoc khi vua (bo HOP va marker tach nhom)
    SELECT @VaTruoc = COUNT(*) FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID AND k.MaLop IN (SELECT MaLop FROM @S) AND k.MaMon <> 'HOP'
      AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = k.MaMon);

    DELETE kk FROM tblTKB_KetQuaXep_Khoa kk INNER JOIN tblTKB_KetQuaXep k ON k.ID = kk.KetQuaXepID
    WHERE k.RunID = @RunID AND k.MaLop IN (SELECT MaLop FROM @S) AND k.MaMon NOT IN ('SH', 'HDTN1', 'HOP')
      AND NOT EXISTS (SELECT 1 FROM tblTKB_OCoDinh_Tuan o WHERE o.Enable = 1 AND o.Tuan = @Tuan AND o.MaLop = k.MaLop AND o.Thu = k.Thu AND o.Buoi = k.Buoi AND o.Tiet = k.Tiet);
    DELETE FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID AND MaLop IN (SELECT MaLop FROM @S) AND MaMon NOT IN ('SH', 'HDTN1', 'HOP')
      AND NOT EXISTS (SELECT 1 FROM tblTKB_OCoDinh_Tuan o WHERE o.Enable = 1 AND o.Tuan = @Tuan AND o.MaLop = tblTKB_KetQuaXep.MaLop
                      AND o.Thu = tblTKB_KetQuaXep.Thu AND o.Buoi = tblTKB_KetQuaXep.Buoi AND o.Tiet = tblTKB_KetQuaXep.Tiet);

    UPDATE tblTKB_ChayNhanh SET VaLop = @VaLop, VaTruoc = @VaTruoc, VaBanSao = @BanSao, VaVong = @Vong,
           NhatKy = LEFT(ISNULL(NhatKy, N'') + N'[va' + CAST(@Vong AS NVARCHAR(2)) + N':' + CAST((SELECT COUNT(*) FROM @S) AS NVARCHAR(5)) + N' lop] ', 2000)
    WHERE RunID = @RunID;
    UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DangChay' WHERE RunID = @RunID;
    EXEC spAPI_TkbChayAuto @Khoi = '', @HocKy = @HocKy, @MaxSecs = @MaxSecs, @TuanHienTai = @Tuan,
         @RunIDDangXay = @RunID, @RunIDNeo = @BanSao, @ChiLop = @VaLop, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
    SET @DaBatDau = 1;
END