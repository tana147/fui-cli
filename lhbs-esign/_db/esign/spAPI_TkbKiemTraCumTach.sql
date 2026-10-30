CREATE PROCEDURE spAPI_TkbKiemTraCumTach
    @RunID INT,
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-10: kiem tra mon to hop / tach nhom THPT (cum tach R23 + cap mon hoc cung gio R24) SAU khi xep. Sinh ra tu loi that:
    -- RunID 1551/1552/1567 tuan 11 xep 12AV1-5 + 12C1/12C2 dung T3 sang tiet 5 la gio chao co khoi 12 (lop nguon dang hoc HDTN1).
    -- Doi chieu lich tay tuan 8-11: nguoi xep tay 0 lan nhom con hoc trung gio lop nguon, 0 lan lop nguon thuoc 2 cum cung luc;
    -- lech nhom chi o cum chuyen de 2 nhom khong deu tiet (11B-CD, 10F-CD, 10A-CD, 12C-CD) — hop le.
    -- Tra: MucDo (LOI / CANHBAO / THONGTIN), Loai, Cum, DoiTuong, Gio, MoTa.
    SET NOCOUNT ON;
    CREATE TABLE #KQ (MucDo VARCHAR(10), Loai NVARCHAR(60), Cum NVARCHAR(20), DoiTuong NVARCHAR(60), Gio NVARCHAR(30), MoTa NVARCHAR(400));

    DECLARE @Tuan INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);

    -- Tiet that cua lop (bo HOP, khoa phong, marker "Tach nhom")
    SELECT k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon
    INTO #T
    FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG')
      AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = k.MaMon);

    SELECT c.ID, c.MaCumTach, n.MaLop INTO #NC FROM tblTKB_CumTach c INNER JOIN tblTKB_CumTach_NhomCon n ON n.CumTachID = c.ID WHERE c.Enable = 1;
    SELECT c.ID, c.MaCumTach, n.MaLop INTO #LN FROM tblTKB_CumTach c INNER JOIN tblTKB_CumTach_LopNguon n ON n.CumTachID = c.ID WHERE c.Enable = 1;

    -- Gio cum "dang tach" = co it nhat 1 nhom con hoc
    SELECT DISTINCT nc.ID, nc.MaCumTach, t.Thu, t.Buoi, t.Tiet INTO #A FROM #NC nc INNER JOIN #T t ON t.MaLop = nc.MaLop;

    -- 1) Nhom con hoc dung gio lop nguon dang hoc mon khac (hoc sinh o 2 noi)
    INSERT #KQ
    SELECT 'LOI', N'Học sinh ở 2 nơi', a.MaCumTach, ln.MaLop,
           N'T' + CAST(a.Thu AS NVARCHAR(2)) + CASE WHEN a.Buoi = 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(a.Tiet AS NVARCHAR(2)),
           N'Lớp ' + ln.MaLop + N' đang học ' + t.MaMon + N' trong khi các nhóm (' +
           (SELECT STRING_AGG(CAST(t2.MaLop + ':' + t2.MaMon AS NVARCHAR(200)), ', ') FROM #NC n2 INNER JOIN #T t2 ON t2.MaLop = n2.MaLop AND t2.Thu = a.Thu AND t2.Buoi = a.Buoi AND t2.Tiet = a.Tiet WHERE n2.ID = a.ID)
           + N') tách ra học cùng giờ.'
    FROM #A a
    INNER JOIN #LN ln ON ln.ID = a.ID
    INNER JOIN #T t ON t.MaLop = ln.MaLop AND t.Thu = a.Thu AND t.Buoi = a.Buoi AND t.Tiet = a.Tiet
    WHERE NOT EXISTS (SELECT 1 FROM #NC x WHERE x.ID = a.ID AND x.MaLop = ln.MaLop);   -- lop vua la nguon vua la nhom thi bo qua

    -- 2) 1 lop nguon thuoc 2 cum cung tach cung gio
    INSERT #KQ
    SELECT 'LOI', N'Lớp ở 2 cụm cùng giờ', STRING_AGG(CAST(a.MaCumTach AS NVARCHAR(100)), ' + '), ln.MaLop,
           N'T' + CAST(a.Thu AS NVARCHAR(2)) + CASE WHEN a.Buoi = 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(a.Tiet AS NVARCHAR(2)),
           N'Học sinh lớp ' + ln.MaLop + N' đang tách nhóm ở ' + CAST(COUNT(*) AS NVARCHAR(2)) + N' cụm cùng lúc.'
    FROM #A a INNER JOIN #LN ln ON ln.ID = a.ID
    GROUP BY ln.MaLop, a.Thu, a.Buoi, a.Tiet
    HAVING COUNT(*) > 1;

    -- 3) Nhom con lech gio trong cum (chi bao voi nhom co du so tiet lon nhat cua cum: nhom it tiet hon duoc phep ve hoc lop me)
    ;WITH Tong AS (SELECT nc.ID, nc.MaLop, (SELECT COUNT(*) FROM #T t WHERE t.MaLop = nc.MaLop) AS SoTiet FROM #NC nc),
    MaxCum AS (SELECT ID, MAX(SoTiet) AS M FROM Tong GROUP BY ID)
    INSERT #KQ
    SELECT 'CANHBAO', N'Nhóm lệch giờ', a.MaCumTach, tg.MaLop,
           N'T' + CAST(a.Thu AS NVARCHAR(2)) + CASE WHEN a.Buoi = 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(a.Tiet AS NVARCHAR(2)),
           N'Các nhóm khác của cụm đang học nhưng nhóm ' + tg.MaLop + N' (đủ tiết nhất cụm) lại trống — học sinh nhóm này không có lớp để học.'
    FROM #A a
    INNER JOIN Tong tg ON tg.ID = a.ID
    INNER JOIN MaxCum m ON m.ID = a.ID AND tg.SoTiet = m.M
    WHERE NOT EXISTS (SELECT 1 FROM #T t WHERE t.MaLop = tg.MaLop AND t.Thu = a.Thu AND t.Buoi = a.Buoi AND t.Tiet = a.Tiet);

    -- 4) Cap mon hoc cung gio (R24) lech
    ;WITH Cap AS (
        SELECT c.MaLopA, c.MaMonA, c.MaLopB, c.MaMonB FROM tblTKB_CapMonDongBoGio c
        WHERE c.Enable = 1 AND (c.Tuan IS NULL OR c.Tuan = @Tuan) AND c.MaLopA NOT LIKE '0%'
          AND NOT EXISTS (SELECT 1 FROM tblTKB_CapMonDongBoGio t WHERE t.Tuan = @Tuan AND t.Enable = 0
                          AND t.MaLopA = c.MaLopA AND t.MaMonA = c.MaMonA AND t.MaLopB = c.MaLopB AND t.MaMonB = c.MaMonB)
    ), A AS (SELECT cp.*, t.Thu, t.Buoi, t.Tiet FROM Cap cp INNER JOIN #T t ON t.MaLop = cp.MaLopA AND t.MaMon = cp.MaMonA),
       B AS (SELECT cp.*, t.Thu, t.Buoi, t.Tiet FROM Cap cp INNER JOIN #T t ON t.MaLop = cp.MaLopB AND t.MaMon = cp.MaMonB)
    INSERT #KQ
    SELECT 'THONGTIN', N'Cặp môn lệch giờ', N'', x.MaLopA + N' ' + x.MaMonA + N' ↔ ' + x.MaLopB + N' ' + x.MaMonB,
           N'T' + CAST(x.Thu AS NVARCHAR(2)) + CASE WHEN x.Buoi = 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(x.Tiet AS NVARCHAR(2)),
           x.MoTa
    FROM (
        SELECT a.MaLopA, a.MaMonA, a.MaLopB, a.MaMonB, a.Thu, a.Buoi, a.Tiet, N'Chỉ ' + a.MaLopA + N' học, ' + a.MaLopB + N' không học ' + a.MaMonB + N' cùng giờ (hợp lệ nếu ' + a.MaLopA + N' nhiều tiết hơn).' AS MoTa
        FROM A a WHERE NOT EXISTS (SELECT 1 FROM B b WHERE b.MaLopA = a.MaLopA AND b.MaMonA = a.MaMonA AND b.MaLopB = a.MaLopB AND b.MaMonB = a.MaMonB AND b.Thu = a.Thu AND b.Buoi = a.Buoi AND b.Tiet = a.Tiet)
        UNION ALL
        SELECT b.MaLopA, b.MaMonA, b.MaLopB, b.MaMonB, b.Thu, b.Buoi, b.Tiet, N'Chỉ ' + b.MaLopB + N' học, ' + b.MaLopA + N' không học ' + b.MaMonA + N' cùng giờ (hợp lệ nếu ' + b.MaLopB + N' nhiều tiết hơn).'
        FROM B b WHERE NOT EXISTS (SELECT 1 FROM A a WHERE a.MaLopA = b.MaLopA AND a.MaMonA = b.MaMonA AND a.MaLopB = b.MaLopB AND a.MaMonB = b.MaMonB AND a.Thu = b.Thu AND a.Buoi = b.Buoi AND a.Tiet = b.Tiet)
    ) x;

    -- 5) Tong quan tung cum
    INSERT #KQ
    SELECT 'THONGTIN', N'Tổng quan cụm', c.MaCumTach,
           CAST((SELECT COUNT(*) FROM #NC n WHERE n.ID = c.ID) AS NVARCHAR(3)) + N' nhóm / ' + CAST((SELECT COUNT(*) FROM #LN n WHERE n.ID = c.ID) AS NVARCHAR(3)) + N' lớp gốc',
           N'', CAST((SELECT COUNT(*) FROM #A a WHERE a.ID = c.ID) AS NVARCHAR(4)) + N' tiết tách nhóm trong tuần.'
    FROM tblTKB_CumTach c WHERE c.Enable = 1;

    SELECT MucDo, Loai, Cum, DoiTuong, Gio, MoTa FROM #KQ
    ORDER BY CASE MucDo WHEN 'LOI' THEN 1 WHEN 'CANHBAO' THEN 2 ELSE 3 END, Loai, Cum, DoiTuong, Gio;
END
