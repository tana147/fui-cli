CREATE PROCEDURE spAPI_TkbChecklistRun
    @RunID INT,
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-10: checklist luat cho 1 lan chay (theo yeu cau nguoi dung: "moi tuan vua Run xong cho 1 check list cac tap luat de biet pass chua").
    -- Moi dong = 1 luat: Nhom, Luat, KetQua (DAT / KHONGDAT / CANHBAO / THONGTIN), SoLan, ViDu (toi da vai vi du).
    -- KHONGDAT = vi pham luat cung (vat ly / luat truong da xac nhan). CANHBAO = luat mem nguoi xep tay cung pha khi can.
    SET NOCOUNT ON;
    DECLARE @Tuan INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    CREATE TABLE #KQ (STT INT IDENTITY, Nhom NVARCHAR(40), Luat NVARCHAR(150), KetQua VARCHAR(10), SoLan INT, ViDu NVARCHAR(600));

    -- Tiet that (bo HOP, khoa phong, marker tach nhom, lop CLB)
    SELECT k.ID, k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon, k.MaGV, k.MaPhong, l.Khoi
    INTO #T
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG') AND k.MaLop NOT LIKE '26%'
      AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = k.MaMon);
    CREATE CLUSTERED INDEX IX_T ON #T (MaLop, Thu, Buoi, Tiet);
    CREATE INDEX IX_T_GV ON #T (MaGV, Thu, Buoi, Tiet);

    -- ===== 1. Vat ly =====
    ;WITH X AS (SELECT MaGV, Thu, Buoi, Tiet, STRING_AGG(CAST(MaLop AS NVARCHAR(MAX)), '+') AS Lops FROM #T WHERE MaGV LIKE 'NV%' GROUP BY MaGV, Thu, Buoi, Tiet HAVING COUNT(DISTINCT MaLop) > 1)
    INSERT #KQ SELECT N'Vật lý', N'Một giáo viên không dạy 2 lớp cùng giờ', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaGV + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) + N': ' + Lops AS v FROM X) z) FROM X;

    ;WITH X AS (SELECT MaLop, Thu, Buoi, Tiet, STRING_AGG(CAST(MaMon AS NVARCHAR(MAX)), '+') AS Mons FROM #T GROUP BY MaLop, Thu, Buoi, Tiet HAVING COUNT(*) > 1)
    INSERT #KQ SELECT N'Vật lý', N'Một lớp không học 2 môn cùng giờ', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) + N': ' + Mons AS v FROM X) z) FROM X;

    ;WITH X AS (SELECT MaPhong, Thu, Buoi, Tiet, STRING_AGG(CAST(MaLop AS NVARCHAR(MAX)), '+') AS Lops FROM #T WHERE ISNULL(MaPhong, '') <> '' GROUP BY MaPhong, Thu, Buoi, Tiet HAVING COUNT(DISTINCT MaLop) > 1)
    INSERT #KQ SELECT N'Vật lý', N'Một phòng không có 2 lớp cùng giờ', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaPhong + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) + N': ' + Lops AS v FROM X) z) FROM X;

    -- ===== 2. Du tiet =====
    SELECT pc.MaLop, pc.MaMon, SUM(pc.SoTietChuanTuan) AS Dm
    INTO #D
    FROM tblTKB_PhanCongGiangDay pc
    WHERE pc.Enable = 1 AND pc.HocKy = 'HK1' AND pc.SoTietChuanTuan > 0 AND pc.MaLop NOT LIKE '26%'
      AND (pc.TuanApDungTu IS NULL OR pc.TuanApDungTu <= @Tuan) AND (pc.TuanApDungDen IS NULL OR pc.TuanApDungDen >= @Tuan)
      AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
    GROUP BY pc.MaLop, pc.MaMon;
    ;WITH C AS (SELECT MaLop, MaMon, COUNT(*) AS N FROM #T GROUP BY MaLop, MaMon),
    X AS (SELECT d.MaLop, d.MaMon, d.Dm - ISNULL(c.N, 0) AS Thieu FROM #D d LEFT JOIN C c ON c.MaLop = d.MaLop AND c.MaMon = d.MaMon WHERE ISNULL(c.N, 0) < d.Dm)
    INSERT #KQ SELECT N'Đủ tiết', N'Mỗi lớp học đủ số tiết từng môn theo phân công tuần', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, ISNULL(SUM(Thieu), 0),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 6 MaLop + N' ' + MaMon + N' thiếu ' + CAST(Thieu AS NVARCHAR(3)) AS v FROM X ORDER BY MaLop) z) FROM X;

    ;WITH C AS (SELECT MaLop, MaMon, COUNT(*) AS N FROM #T GROUP BY MaLop, MaMon),
    X AS (SELECT c.MaLop, c.MaMon, c.N - ISNULL(d.Dm, 0) AS Du FROM C c LEFT JOIN #D d ON d.MaLop = c.MaLop AND d.MaMon = c.MaMon WHERE c.N > ISNULL(d.Dm, 0))
    INSERT #KQ SELECT N'Đủ tiết', N'Không xếp thừa tiết so với phân công', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, ISNULL(SUM(Du), 0),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 6 MaLop + N' ' + MaMon + N' thừa ' + CAST(Du AS NVARCHAR(3)) AS v FROM X ORDER BY MaLop) z) FROM X;

    -- ===== 3. Lich ban, hop, ngay nghi =====
    SELECT DISTINCT l.MaLop, nn.Thu, b.Buoi, t.Tiet INTO #NN
    FROM tblTKB_NgayNghi_Tuan nn
    CROSS APPLY (SELECT MaLop FROM tblTKB_Lop WHERE Enable = 1 AND ((nn.PhamVi = 'LOP' AND MaLop = nn.MaLop) OR (nn.PhamVi = 'KHOI' AND Khoi = nn.Khoi) OR nn.PhamVi = 'TRUONG')) l
    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(nn.Buoi, '') = '' OR nn.Buoi = x.Buoi) b
    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE nn.Tiet IS NULL OR nn.Tiet = y.Tiet) t
    WHERE nn.Tuan = @Tuan;
    -- bo qua SH: sinh hoat lop do Round 1 khoa theo luat rieng (vd 08C SH sang T6 tiet 3 — nguoi dung xac nhan dung ca tuan thi)
    ;WITH X AS (SELECT t.* FROM #T t INNER JOIN #NN n ON n.MaLop = t.MaLop AND n.Thu = t.Thu AND n.Buoi = t.Buoi AND n.Tiet = t.Tiet WHERE t.MaMon <> 'SH')
    INSERT #KQ SELECT N'Lịch tuần', N'Không xếp tiết vào ngày/buổi lớp nghỉ', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X) z) FROM X;

    SELECT DISTINCT g.MaGV, g.Thu, b.Buoi, t.Tiet INTO #B
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(g.Buoi, '') = '' OR g.Buoi = x.Buoi) b
    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) t
    WHERE g.Tuan = @Tuan;
    ;WITH X AS (SELECT t.* FROM #T t INNER JOIN #B b ON b.MaGV = t.MaGV AND b.Thu = t.Thu AND b.Buoi = t.Buoi AND b.Tiet = t.Tiet)
    INSERT #KQ SELECT N'Lịch tuần', N'Giáo viên không dạy vào giờ đã báo bận', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaGV + N' ' + MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X) z) FROM X;

    SELECT DISTINCT h.MaGV, h.Thu, h.Buoi, h.Tiet, h.LoaiNhom INTO #H FROM dbo.fnTkbLichHopGV(@Tuan) h WHERE h.LoaiNhom <> 'KhoiCap23SH';
    ;WITH X AS (SELECT t.* FROM #T t WHERE EXISTS (SELECT 1 FROM #H h WHERE h.MaGV = t.MaGV AND h.Thu = t.Thu AND h.Buoi = t.Buoi AND h.Tiet = t.Tiet))
    INSERT #KQ SELECT N'Lịch tuần', N'Giáo viên không dạy trong giờ họp', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaGV + N' ' + MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X) z) FROM X;

    ;WITH O AS (
        SELECT l.MaLop, h.Thu, h.Buoi, h.Tiet FROM tblTKB_Lop l INNER JOIN #H h ON h.MaGV = l.GVCN
        WHERE l.Enable = 1 AND l.Khoi < '06' AND LEN(l.MaLop) = 3 AND h.Tiet <= 4
          AND NOT EXISTS (SELECT 1 FROM #NN n WHERE n.MaLop = l.MaLop AND n.Thu = h.Thu AND n.Buoi = h.Buoi AND n.Tiet = h.Tiet)
    ), X AS (SELECT DISTINCT o.* FROM O o WHERE NOT EXISTS (SELECT 1 FROM #T t WHERE t.MaLop = o.MaLop AND t.Thu = o.Thu AND t.Buoi = o.Buoi AND t.Tiet = o.Tiet))
    INSERT #KQ SELECT N'Tiểu học', N'Giờ GVCN họp, lớp có giáo viên bộ môn dạy (không bỏ trống)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X) z) FROM X;

    -- 2026-10-16: tiet trong giua buoi (nguoi dung: "nguyen tac la ko chua trong", chi trong tiet cuoi buoi). Lop khoi 06-12;
    -- o cua nhom tach (10A1, 12C2...) va marker cum tach (12-AV) tinh la lop goc dang hoc. Trong = co tiet sau trong cung buoi.
    -- 2026-10-16: khung THCS theo lich tay that (tuan 8,9,11): sang tiet 1-4 du ca 5 ngay; chieu khoi 6-7 = T2 4, T3 3, T4 4, T5 3, T6 3;
    -- khoi 8-9 = T2 3, T3 4, T4 3, T5 4, T6 3 (tiet 5 sang la phan du, ~1 ngay/tuan). Bat ca buoi trong hoan toan (vd 07E sang T3).
    SELECT c.MaLop, d.Thu, b.Buoi, t.Tiet INTO #KH
    FROM (SELECT MaLop, LEFT(MaLop, 2) AS K FROM tblTKB_Lop WHERE Enable = 1 AND LEN(MaLop) = 3 AND LEFT(MaLop, 2) IN ('06','07','09')
          AND EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = tblTKB_Lop.MaLop)) c
    CROSS JOIN (VALUES(2),(3),(4),(5),(6)) d(Thu) CROSS JOIN (VALUES('Sang'),('Chieu')) b(Buoi) CROSS JOIN (VALUES(1),(2),(3),(4)) t(Tiet)
    WHERE b.Buoi = 'Sang' OR t.Tiet <= CASE WHEN c.K IN ('06','07') THEN CASE WHEN d.Thu IN (2,4) THEN 4 ELSE 3 END ELSE 3 END;
    ;WITH O AS (
        SELECT DISTINCT CASE WHEN LEN(k.MaLop) > 3 AND k.MaLop NOT LIKE '__AV%' AND EXISTS (SELECT 1 FROM tblTKB_Lop p WHERE p.MaLop = LEFT(k.MaLop, 3)) THEN LEFT(k.MaLop, 3) ELSE k.MaLop END AS MaLop, k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG')
    ), X AS (SELECT h.* FROM #KH h WHERE NOT EXISTS (SELECT 1 FROM O o WHERE o.MaLop = h.MaLop AND o.Thu = h.Thu AND o.Buoi = h.Buoi AND o.Tiet = h.Tiet)
             AND NOT EXISTS (SELECT 1 FROM #NN n WHERE n.MaLop = h.MaLop AND n.Thu = h.Thu AND n.Buoi = h.Buoi AND n.Tiet = h.Tiet))
    INSERT #KQ SELECT N'Lịch tuần', N'Khung THCS: sáng đủ tiết 1–4, chiều đủ khung (khối 6–7: T2,T4 4 tiết, còn lại 3; khối 9: 3 tiết)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 6 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X ORDER BY MaLop, Thu, Buoi, Tiet) z) FROM X;
    ;WITH O AS (SELECT DISTINCT MaLop, Thu FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND LEN(MaLop) = 3 AND LEFT(MaLop, 2) IN ('06','07','09') AND Buoi = 'Sang' AND Tiet = 5 AND MaMon NOT IN ('HOP','KHOAPHONG')),
    X AS (SELECT MaLop, COUNT(*) AS N FROM O GROUP BY MaLop HAVING COUNT(*) > 1)
    INSERT #KQ SELECT N'Lịch tuần', N'Tiết 5 sáng chỉ dùng phần dư (khối 6–7, 9: tối đa 1 ngày/tuần)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 6 MaLop + N': ' + CAST(N AS NVARCHAR(2)) + N' ngày' AS v FROM X ORDER BY N DESC, MaLop) z) FROM X;

    ;WITH O AS (
        SELECT DISTINCT CASE WHEN LEN(k.MaLop) > 3 AND k.MaLop NOT LIKE '__AV%' AND EXISTS (SELECT 1 FROM tblTKB_Lop p WHERE p.MaLop = LEFT(k.MaLop, 3)) THEN LEFT(k.MaLop, 3) ELSE k.MaLop END AS MaLop,
               k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG') AND k.MaLop NOT LIKE '26%'
    ), B AS (SELECT MaLop, Thu, Buoi, MAX(Tiet) AS TietCuoi FROM O WHERE LEN(MaLop) = 3 AND LEFT(MaLop, 2) BETWEEN '01' AND '12' GROUP BY MaLop, Thu, Buoi),
    X AS (SELECT b.MaLop, b.Thu, b.Buoi, t.Tiet FROM B b CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4)) v(Tiet) WHERE v.Tiet < b.TietCuoi) t
          WHERE NOT EXISTS (SELECT 1 FROM O o WHERE o.MaLop = b.MaLop AND o.Thu = b.Thu AND o.Buoi = b.Buoi AND o.Tiet = t.Tiet))
    INSERT #KQ SELECT N'Lịch tuần', N'Không có tiết trống giữa buổi (mọi khối, chỉ được trống tiết cuối)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 6 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X ORDER BY MaLop, Thu, Buoi, Tiet) z) FROM X;

    -- ===== 4. Luat mon (MonQuyTac) =====
    ;WITH QT AS (
        SELECT q.MaMon, q.Khoi, TRY_CAST(JSON_VALUE(q.ThamSo, '$.soTiet') AS INT) AS SoTiet, TRY_CAST(JSON_VALUE(q.ThamSo, '$.tuan') AS INT) AS TuanQT
        FROM tblTKB_MonQuyTac q WHERE q.Enable = 1 AND q.LoaiQuyTac = 'MaxTietMoiNgay'
    ), Q AS (
        SELECT a.MaMon, a.Khoi, a.SoTiet FROM QT a
        WHERE a.TuanQT = @Tuan OR (a.TuanQT IS NULL AND NOT EXISTS (SELECT 1 FROM QT b WHERE b.MaMon = a.MaMon AND ISNULL(b.Khoi, '') = ISNULL(a.Khoi, '') AND b.TuanQT = @Tuan))
    ), X AS (
        SELECT t.MaLop, t.MaMon, t.Thu, COUNT(*) AS N, MAX(q.SoTiet) AS Max_
        FROM #T t INNER JOIN Q q ON q.MaMon = t.MaMon AND (q.Khoi IS NULL OR q.Khoi = t.Khoi)
        GROUP BY t.MaLop, t.MaMon, t.Thu HAVING COUNT(*) > MAX(q.SoTiet)
    )
    INSERT #KQ SELECT N'Luật môn', N'Số tiết/ngày tối đa của môn (vd Toán tiểu học 1 tiết/ngày)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' T' + CAST(Thu AS NVARCHAR(2)) + N': ' + CAST(N AS NVARCHAR(2)) + N' tiết' AS v FROM X) z) FROM X;

    ;WITH Q AS (
        SELECT q.MaMon, q.Khoi, JSON_VALUE(q.ThamSo, '$.buoi') AS Buoi, TRY_CAST(JSON_VALUE(q.ThamSo, '$.tiet') AS INT) AS Tiet
        FROM tblTKB_MonQuyTac q WHERE q.Enable = 1 AND q.LoaiQuyTac = 'CamKhungGio'
    ), X AS (SELECT t.* FROM #T t INNER JOIN Q q ON q.MaMon = t.MaMon AND (q.Khoi IS NULL OR q.Khoi = t.Khoi) AND q.Buoi = t.Buoi AND q.Tiet = t.Tiet)
    INSERT #KQ SELECT N'Luật môn', N'Môn không xếp vào khung giờ cấm (vd SHTV chiều tiết 1)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) AS v FROM X) z) FROM X;

    ;WITH X AS (
        SELECT t.MaLop, t.Thu, t.Buoi, COUNT(*) AS N,
               SUM(CASE WHEN t.MaMon IN ('TANN', 'ENG1') THEN 1 ELSE 0 END) AS NN, SUM(CASE WHEN t.MaMon IN ('TAVN', 'ENG2') THEN 1 ELSE 0 END) AS VN
        FROM #T t WHERE t.MaMon IN ('TANN', 'TAVN', 'ENG1', 'ENG2') GROUP BY t.MaLop, t.Thu, t.Buoi
    ), Y AS (SELECT MaLop, Thu, SUM(N) AS N FROM X GROUP BY MaLop, Thu HAVING SUM(N) > 4)
    INSERT #KQ SELECT N'Luật môn', N'Tiếng Anh tối đa 4 tiết/ngày', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + N': ' + CAST(N AS NVARCHAR(2)) AS v FROM Y) z) FROM Y;
    ;WITH X AS (
        SELECT t.MaLop, t.Thu, t.Buoi,
               SUM(CASE WHEN t.MaMon IN ('TANN', 'ENG1') THEN 1 ELSE 0 END) AS NN, SUM(CASE WHEN t.MaMon IN ('TAVN', 'ENG2') THEN 1 ELSE 0 END) AS VN
        FROM #T t WHERE t.MaMon IN ('TANN', 'TAVN', 'ENG1', 'ENG2') GROUP BY t.MaLop, t.Thu, t.Buoi HAVING SUM(CASE WHEN t.MaMon IN ('TANN', 'ENG1') THEN 1 ELSE 0 END) > 0 AND SUM(CASE WHEN t.MaMon IN ('TAVN', 'ENG2') THEN 1 ELSE 0 END) > 0
    )
    INSERT #KQ SELECT N'Luật môn', N'Không học TA giáo viên nước ngoài và TA Việt Nam chung một buổi', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) AS v FROM X) z) FROM X;

    ;WITH X AS (SELECT t.* FROM #T t WHERE t.MaMon = 'TOAN' AND t.Khoi < '06'), Y AS (SELECT MaLop, Thu FROM X GROUP BY MaLop, Thu HAVING COUNT(*) > 2)
    INSERT #KQ SELECT N'Luật môn', N'Tiểu học không có ngày học quá 2 tiết Toán', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' T' + CAST(Thu AS NVARCHAR(2)) AS v FROM Y) z) FROM Y;

    -- Mon bat buoc tiet doi: so tiet le vuot muc bat buoc (mon co so tiet le thi duoc 1 tiet le)
    ;WITH L AS (
        SELECT t.MaLop, t.MaMon, t.Thu, t.Buoi, t.Tiet,
               CASE WHEN EXISTS (SELECT 1 FROM #T u WHERE u.MaLop = t.MaLop AND u.MaMon = t.MaMon AND u.Thu = t.Thu AND u.Buoi = t.Buoi AND ABS(u.Tiet - t.Tiet) = 1) THEN 0 ELSE 1 END AS Le
        FROM #T t INNER JOIN tblTKB_MonHoc m ON m.MaMon = t.MaMon AND m.BatBuocXepDoi = 1
    ), X AS (
        SELECT MaLop, MaMon, SUM(Le) - COUNT(*) % 2 AS Vuot,
               MIN(CASE WHEN Le = 1 THEN N'T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) + CAST(Tiet AS NVARCHAR(2)) END) AS Gio
        FROM L GROUP BY MaLop, MaMon HAVING SUM(Le) - COUNT(*) % 2 > 0
    )
    INSERT #KQ SELECT N'Tiết đôi', N'Môn bắt buộc tiết đôi không bị tách lẻ', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, ISNULL(SUM(Vuot), 0),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' ' + Gio AS v FROM X) z) FROM X;

    ;WITH X AS (
        SELECT a.MaLop, a.MaMon, a.Thu, a.Buoi FROM #T a
        INNER JOIN #T b ON b.MaLop = a.MaLop AND b.MaMon = a.MaMon AND b.Thu = a.Thu AND b.Buoi = a.Buoi AND a.Tiet = 2 AND b.Tiet = 3
        INNER JOIN tblTKB_MonHoc m ON m.MaMon = a.MaMon AND m.BatBuocXepDoi = 1
        WHERE NOT EXISTS (SELECT 1 FROM #T c WHERE c.MaLop = a.MaLop AND c.MaMon = a.MaMon AND c.Thu = a.Thu AND c.Buoi = a.Buoi AND c.Tiet IN (1, 4))
    )
    INSERT #KQ SELECT N'Tiết đôi', N'Tiết đôi nằm đúng nhịp 1–2 hoặc 3–4 (không vắt qua giờ ra chơi)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) AS v FROM X) z) FROM X;

    ;WITH Q AS (SELECT q.MaMon, q.Khoi FROM tblTKB_MonQuyTac q WHERE q.Enable = 1 AND q.LoaiQuyTac = 'KhongXepLien'),
    X AS (
        SELECT DISTINCT a.MaLop, a.MaMon, a.Thu, a.Buoi FROM #T a
        INNER JOIN Q q ON q.MaMon = a.MaMon AND (q.Khoi IS NULL OR q.Khoi = a.Khoi)
        INNER JOIN #T b ON b.MaLop = a.MaLop AND b.MaMon = a.MaMon AND b.Thu = a.Thu AND b.Buoi = a.Buoi AND b.Tiet = a.Tiet + 1
    )
    INSERT #KQ SELECT N'Tiết đôi', N'Môn không được ghép 2 tiết liền (GDTC, KH, LS&ĐL, TNXH, Sử)', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaLop + N' ' + MaMon + N' T' + CAST(Thu AS NVARCHAR(2)) + LEFT(Buoi, 1) AS v FROM X) z) FROM X;

    -- ===== 5. Giao vien =====
    ;WITH X AS (SELECT MaGV, Thu, COUNT(DISTINCT CAST(Buoi AS VARCHAR(10)) + CAST(Tiet AS VARCHAR(2))) AS N FROM #T WHERE MaGV LIKE 'NV%' GROUP BY MaGV, Thu HAVING COUNT(DISTINCT CAST(Buoi AS VARCHAR(10)) + CAST(Tiet AS VARCHAR(2))) > 8)
    INSERT #KQ SELECT N'Giáo viên', N'Giáo viên dạy tối đa 8 tiết/ngày', CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 4 MaGV + N' T' + CAST(Thu AS NVARCHAR(2)) + N': ' + CAST(N AS NVARCHAR(2)) + N' tiết' AS v FROM X) z) FROM X;

    -- ===== 6. Mon to hop / tach nhom THPT =====
    DECLARE @ct TABLE (MucDo VARCHAR(10), Loai NVARCHAR(60), Cum NVARCHAR(100), DoiTuong NVARCHAR(100), Gio NVARCHAR(30), MoTa NVARCHAR(400));
    INSERT INTO @ct EXEC spAPI_TkbKiemTraCumTach @RunID = @RunID, @sys_UserID = @sys_UserID;
    INSERT #KQ SELECT N'Tổ hợp THPT', N'Học sinh không ở 2 nơi (nhóm tách học lúc lớp gốc đang học môn khác)',
        CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 3 DoiTuong + N' ' + Gio + N' (' + Cum + N')' AS v FROM @ct WHERE Loai = N'Học sinh ở 2 nơi') z)
    FROM @ct WHERE Loai = N'Học sinh ở 2 nơi';
    INSERT #KQ SELECT N'Tổ hợp THPT', N'Một lớp gốc không tách nhóm ở 2 cụm cùng giờ',
        CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'KHONGDAT' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 3 DoiTuong + N' ' + Gio + N' (' + Cum + N')' AS v FROM @ct WHERE Loai = N'Lớp ở 2 cụm cùng giờ') z)
    FROM @ct WHERE Loai = N'Lớp ở 2 cụm cùng giờ';
    INSERT #KQ SELECT N'Tổ hợp THPT', N'Các nhóm trong một cụm tách cùng giờ (nhóm đủ tiết không bị trống)',
        CASE WHEN COUNT(*) = 0 THEN 'DAT' ELSE 'CANHBAO' END, COUNT(*),
        (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), '; ') FROM (SELECT TOP 3 DoiTuong + N' ' + Gio AS v FROM @ct WHERE Loai = N'Nhóm lệch giờ') z)
    FROM @ct WHERE Loai = N'Nhóm lệch giờ';

    -- ===== 7. Thong tin: giu o so voi tuan nguon (neo) — tach bang tam co chi muc (truoc day 30s, tAPI timeout) =====
    SELECT Tuan, LEFT(MaLop, 2) AS Khoi, COUNT(*) AS Cnt INTO #Dem FROM tblTKB_NeoO WHERE Enable = 1 AND Tuan < @Tuan GROUP BY Tuan, LEFT(MaLop, 2);
    SELECT d.Khoi, COALESCE(MAX(CASE WHEN d.CoNghi = 0 THEN d.Tuan END), MAX(d.Tuan)) AS Tuan
    INTO #Src
    FROM (SELECT x.*, CASE WHEN EXISTS (SELECT 1 FROM tblTKB_NgayNghi_Tuan nn WHERE nn.Tuan = x.Tuan AND (nn.PhamVi = 'TRUONG' OR (nn.PhamVi = 'KHOI' AND nn.Khoi = x.Khoi) OR (nn.PhamVi = 'LOP' AND LEFT(nn.MaLop, 2) = x.Khoi))) THEN 1 ELSE 0 END AS CoNghi FROM #Dem x) d
    INNER JOIN (SELECT Khoi, MAX(Cnt) AS MaxCnt FROM #Dem GROUP BY Khoi) m ON m.Khoi = d.Khoi
    WHERE d.Cnt >= 0.85 * m.MaxCnt GROUP BY d.Khoi;
    SELECT DISTINCT n.MaLop, n.MaMon, n.Thu, n.Buoi, n.Tiet INTO #N
    FROM tblTKB_NeoO n INNER JOIN #Src s ON s.Khoi = LEFT(n.MaLop, 2) AND s.Tuan = n.Tuan WHERE n.Enable = 1;
    CREATE CLUSTERED INDEX IX_N ON #N (MaLop, Thu, Buoi, Tiet);
    ;WITH F AS (
        SELECT CASE WHEN t.Khoi < '06' THEN N'TH' WHEN t.Khoi < '10' THEN N'THCS' ELSE N'THPT' END AS Cap, CASE WHEN n.MaLop IS NULL THEN 0 ELSE 1 END AS Giu
        FROM #T t LEFT JOIN #N n ON n.MaLop = t.MaLop AND n.Thu = t.Thu AND n.Buoi = t.Buoi AND n.Tiet = t.Tiet AND n.MaMon = t.MaMon
        WHERE t.Khoi IS NOT NULL
    ), G AS (SELECT Cap, COUNT(*) AS Tong, SUM(Giu) AS Giu FROM F GROUP BY Cap)
    INSERT #KQ SELECT N'Ổn định', N'Tiết giữ đúng giờ như tuần nguồn (tuần trước học đủ ngày)', 'THONGTIN', SUM(Giu),
        STRING_AGG(CAST(Cap + N' ' + CAST(CAST(100.0 * Giu / NULLIF(Tong, 0) AS DECIMAL(5,1)) AS NVARCHAR(10)) + N'%' AS NVARCHAR(MAX)), ' · ')
    FROM G;

    SELECT STT, Nhom, Luat, KetQua, SoLan, ISNULL(ViDu, N'') AS ViDu FROM #KQ ORDER BY STT;
END