CREATE PROCEDURE spAPI_TkbChuyenTuanPhanTich
    @Tuan INT,
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-10 (giai doan 1 "chuyen tuan = sua tuan truoc"): phan tich TRUOC khi xep tuan @Tuan — chep o cua tuan nguon (theo khoi,
    -- giong spAPI_TkbChayAuto) sang tuan nay thi bao nhieu o con dung duoc, bao nhieu o vo va vi sao. Chi doc, khong ghi.
    -- Tra 1 dong/khoi + dong 'Toan truong': TuanNguon, SoONguon, GoNghi (ngay nghi/lop nghi), GoBan (GV bao ban), GoHop (GV hop),
    -- GoDinhMuc (dinh muc lop-mon giam so voi tuan nguon), SoOGiu, CanThem (tiet can xep moi: dinh muc tang/mon moi), PhanTramGiu.
    SET NOCOUNT ON;

    CREATE TABLE #N (MaLop VARCHAR(10), MaMon NVARCHAR(30), Thu INT, Buoi VARCHAR(10), Tiet INT, Khoi VARCHAR(2), TuanNguon INT, LyDo VARCHAR(10) NULL);
    ;WITH Dem AS (
        SELECT Tuan, LEFT(MaLop, 2) AS Khoi, COUNT(*) AS Cnt FROM tblTKB_NeoO WHERE Enable = 1 AND Tuan < @Tuan GROUP BY Tuan, LEFT(MaLop, 2)
    ), Mx AS (SELECT Khoi, MAX(Cnt) AS MaxCnt FROM Dem GROUP BY Khoi),
    Src AS (SELECT d.Khoi, COALESCE(MAX(CASE WHEN d.CoNghi = 0 THEN d.Tuan END), MAX(d.Tuan)) AS Tuan FROM (SELECT x.*, CASE WHEN EXISTS (SELECT 1 FROM tblTKB_NgayNghi_Tuan nn WHERE nn.Tuan = x.Tuan AND (nn.PhamVi = 'TRUONG' OR (nn.PhamVi = 'KHOI' AND nn.Khoi = x.Khoi) OR (nn.PhamVi = 'LOP' AND LEFT(nn.MaLop, 2) = x.Khoi))) THEN 1 ELSE 0 END AS CoNghi FROM Dem x) d INNER JOIN Mx m ON m.Khoi = d.Khoi WHERE d.Cnt >= 0.85 * m.MaxCnt GROUP BY d.Khoi)
    INSERT #N (MaLop, MaMon, Thu, Buoi, Tiet, Khoi, TuanNguon)
    SELECT n.MaLop, n.MaMon, n.Thu, n.Buoi, n.Tiet, LEFT(n.MaLop, 2), s.Tuan
    FROM tblTKB_NeoO n
    INNER JOIN Src s ON s.Khoi = LEFT(n.MaLop, 2) AND s.Tuan = n.Tuan
    WHERE n.Enable = 1
      AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac q WHERE q.MaMon = n.MaMon AND q.LoaiQuyTac = 'NeoTuanTruoc' AND q.Enable = 1
                  AND (q.Khoi IS NULL OR q.Khoi = LEFT(n.MaLop, 2)));

    -- dinh muc hieu luc cua tuan @Tuan (+ 1 GV day lop-mon de doi chieu lich ban/hop)
    SELECT pc.MaLop, pc.MaMon, MAX(pc.MaGV) AS MaGV, SUM(pc.SoTietChuanTuan) AS Dm
    INTO #D
    FROM tblTKB_PhanCongGiangDay pc
    WHERE pc.Enable = 1 AND pc.HocKy = 'HK1'
      AND (pc.TuanApDungTu IS NULL OR pc.TuanApDungTu <= @Tuan) AND (pc.TuanApDungDen IS NULL OR pc.TuanApDungDen >= @Tuan)
      AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
      AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac q WHERE q.MaMon = pc.MaMon AND q.LoaiQuyTac = 'NeoTuanTruoc' AND q.Enable = 1)
    GROUP BY pc.MaLop, pc.MaMon;

    -- o nghi cua lop trong tuan @Tuan (da resolve pham vi Lop/Khoi/Truong)
    SELECT DISTINCT l.MaLop, nn.Thu, b.Buoi, t.Tiet
    INTO #NN
    FROM tblTKB_NgayNghi_Tuan nn
    CROSS APPLY (SELECT MaLop FROM tblTKB_Lop WHERE Enable = 1 AND ((nn.PhamVi = 'LOP' AND MaLop = nn.MaLop) OR (nn.PhamVi = 'KHOI' AND Khoi = nn.Khoi) OR nn.PhamVi = 'TRUONG')) l
    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(nn.Buoi, '') = '' OR nn.Buoi = x.Buoi) b
    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE nn.Tiet IS NULL OR nn.Tiet = y.Tiet) t
    WHERE nn.Tuan = @Tuan;

    SELECT DISTINCT g.MaGV, g.Thu, b.Buoi, t.Tiet
    INTO #B
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(g.Buoi, '') = '' OR g.Buoi = x.Buoi) b
    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) t
    WHERE g.Tuan = @Tuan;

    SELECT DISTINCT h.MaGV, h.Thu, h.Buoi, h.Tiet INTO #H FROM dbo.fnTkbLichHopGV(@Tuan) h WHERE h.LoaiNhom <> 'KhoiCap23SH';

    UPDATE n SET LyDo = 'NGHI' FROM #N n WHERE EXISTS (SELECT 1 FROM #NN x WHERE x.MaLop = n.MaLop AND x.Thu = n.Thu AND x.Buoi = n.Buoi AND x.Tiet = n.Tiet);
    UPDATE n SET LyDo = 'BAN' FROM #N n INNER JOIN #D d ON d.MaLop = n.MaLop AND d.MaMon = n.MaMon
        WHERE n.LyDo IS NULL AND EXISTS (SELECT 1 FROM #B x WHERE x.MaGV = d.MaGV AND x.Thu = n.Thu AND x.Buoi = n.Buoi AND x.Tiet = n.Tiet);
    UPDATE n SET LyDo = 'HOP' FROM #N n INNER JOIN #D d ON d.MaLop = n.MaLop AND d.MaMon = n.MaMon
        WHERE n.LyDo IS NULL AND EXISTS (SELECT 1 FROM #H x WHERE x.MaGV = d.MaGV AND x.Thu = n.Thu AND x.Buoi = n.Buoi AND x.Tiet = n.Tiet);

    -- theo (lop, mon): o con dung duoc so voi dinh muc moi
    SELECT COALESCE(a.MaLop, d.MaLop) AS MaLop, COALESCE(a.MaMon, d.MaMon) AS MaMon, COALESCE(a.Khoi, LEFT(d.MaLop, 2)) AS Khoi,
           ISNULL(a.TuanNguon, 0) AS TuanNguon, ISNULL(a.Tong, 0) AS Tong, ISNULL(a.Nghi, 0) AS Nghi, ISNULL(a.Ban, 0) AS Ban, ISNULL(a.Hop, 0) AS Hop,
           ISNULL(a.Con, 0) AS Con, ISNULL(d.Dm, 0) AS Dm
    INTO #LM
    FROM (SELECT MaLop, MaMon, MAX(Khoi) AS Khoi, MAX(TuanNguon) AS TuanNguon, COUNT(*) AS Tong,
                 SUM(CASE WHEN LyDo = 'NGHI' THEN 1 ELSE 0 END) AS Nghi, SUM(CASE WHEN LyDo = 'BAN' THEN 1 ELSE 0 END) AS Ban,
                 SUM(CASE WHEN LyDo = 'HOP' THEN 1 ELSE 0 END) AS Hop, SUM(CASE WHEN LyDo IS NULL THEN 1 ELSE 0 END) AS Con
          FROM #N GROUP BY MaLop, MaMon) a
    FULL OUTER JOIN #D d ON d.MaLop = a.MaLop AND d.MaMon = a.MaMon;

    SELECT CASE WHEN GROUPING(Khoi) = 1 THEN N'Toàn trường' ELSE Khoi END AS Khoi,
           MAX(TuanNguon) AS TuanNguon,
           SUM(Tong) AS SoONguon, SUM(Nghi) AS GoNghi, SUM(Ban) AS GoBan, SUM(Hop) AS GoHop,
           SUM(CASE WHEN Con > Dm THEN Con - Dm ELSE 0 END) AS GoDinhMuc,
           SUM(CASE WHEN Con < Dm THEN Con ELSE Dm END) AS SoOGiu,
           SUM(CASE WHEN Dm > Con THEN Dm - Con ELSE 0 END) AS CanThem,
           CAST(100.0 * SUM(CASE WHEN Con < Dm THEN Con ELSE Dm END) / NULLIF(SUM(Dm), 0) AS DECIMAL(5,1)) AS PhanTramGiu
    FROM #LM
    GROUP BY GROUPING SETS ((Khoi), ())
    ORDER BY GROUPING(Khoi), Khoi;
END
