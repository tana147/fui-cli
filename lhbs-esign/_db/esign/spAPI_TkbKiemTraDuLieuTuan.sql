CREATE PROCEDURE spAPI_TkbKiemTraDuLieuTuan
    @Tuan INT,
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-10 (ke hoach TKB, buoc 2): kiem tra du lieu tuan @Tuan TRUOC khi xep. Moi muc kiem tra sinh ra tu 1 su co that:
    -- lop TG thieu phan cong (tuan 8 thieu 140 tiet TA khoi 1), GV trung ten (tuan 11 thieu 13 tiet Su), GV it o ranh hon so tiet
    -- (Thanh Hien bi chan 33 o), tuan cat ngay lam luat theo ngay vo nghiem (tuan 12 Toan TH 5 tiet/4 ngay), gio hop GVCN TH khong du
    -- GV bo mon (khoi 5 tuan 11), hop uoc tinh... Chi doc. Tra: MucDo (LOI = chan chay / CANHBAO / THONGTIN), Nhom, DoiTuong, MoTa, GoiY.
    SET NOCOUNT ON;

    CREATE TABLE #KQ (MucDo VARCHAR(10), Nhom NVARCHAR(50), DoiTuong NVARCHAR(100), MoTa NVARCHAR(400), GoiY NVARCHAR(300));

    -- Dinh muc lop-mon hieu luc cua tuan
    SELECT pc.MaLop, pc.MaMon, pc.MaGV, SUM(pc.SoTietChuanTuan) AS Dm
    INTO #PC
    FROM tblTKB_PhanCongGiangDay pc
    WHERE pc.Enable = 1 AND pc.HocKy = 'HK1' AND pc.SoTietChuanTuan > 0
      AND (pc.TuanApDungTu IS NULL OR pc.TuanApDungTu <= @Tuan) AND (pc.TuanApDungDen IS NULL OR pc.TuanApDungDen >= @Tuan)
      AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
    GROUP BY pc.MaLop, pc.MaMon, pc.MaGV;
    SELECT MaLop, MaMon, SUM(Dm) AS Dm INTO #D FROM #PC GROUP BY MaLop, MaMon;

    -- Khung o cua tung lop (TH: sang 1-4 + chieu 1-4; 6-12: sang 1-5 + chieu 1-4) tru o nghi tuan nay
    SELECT l.MaLop, l.Khoi, t.Thu, b.Buoi, x.Tiet
    INTO #O
    FROM tblTKB_Lop l
    CROSS JOIN (VALUES(2),(3),(4),(5),(6)) t(Thu)
    CROSS JOIN (VALUES('Sang'),('Chieu')) b(Buoi)
    CROSS JOIN (VALUES(1),(2),(3),(4),(5)) x(Tiet)
    WHERE l.Enable = 1 AND l.MaLop NOT LIKE '26%'
      AND (x.Tiet <= 4 OR (b.Buoi = 'Sang' AND l.Khoi >= '06'));
    DELETE o FROM #O o
    WHERE EXISTS (SELECT 1 FROM tblTKB_NgayNghi_Tuan n
                  WHERE n.Tuan = @Tuan AND n.Thu = o.Thu
                    AND ((n.PhamVi = 'LOP' AND n.MaLop = o.MaLop) OR (n.PhamVi = 'KHOI' AND n.Khoi = o.Khoi) OR n.PhamVi = 'TRUONG')
                    AND (ISNULL(n.Buoi, '') = '' OR n.Buoi = o.Buoi) AND (n.Tiet IS NULL OR n.Tiet = o.Tiet));

    -- 1) Lop hoc cung gio (lop TG / cap dong bo) ma 1 ben co mon, ben kia khong co phan cong tuan nay
    ;WITH Cap AS (
        SELECT c.MaLopA, c.MaMonA, c.MaLopB, c.MaMonB FROM tblTKB_CapMonDongBoGio c
        WHERE c.Enable = 1 AND (c.Tuan IS NULL OR c.Tuan = @Tuan)
          AND NOT EXISTS (SELECT 1 FROM tblTKB_CapMonDongBoGio t WHERE t.Tuan = @Tuan AND t.Enable = 0
                          AND t.MaLopA = c.MaLopA AND t.MaMonA = c.MaMonA AND t.MaLopB = c.MaLopB AND t.MaMonB = c.MaMonB)
    )
    INSERT #KQ
    SELECT 'LOI', N'Lớp học cùng giờ', c.MaLopB + N' · ' + c.MaMonB,
           N'Lớp ' + c.MaLopA + N' học ' + c.MaMonA + N' ' + CAST(ISNULL(a.Dm, 0) AS NVARCHAR(5)) + N' tiết, phải học cùng giờ với lớp ' + c.MaLopB
           + N' môn ' + c.MaMonB + N' nhưng lớp này có ' + CAST(ISNULL(b.Dm, 0) AS NVARCHAR(5)) + N' tiết tuần ' + CAST(@Tuan AS NVARCHAR(5)) + N'.',
           N'Thêm hoặc sửa phân công tuần này cho lớp ' + CASE WHEN ISNULL(b.Dm, 0) = 0 THEN c.MaLopB ELSE c.MaLopA END + N', hoặc tắt cặp học cùng giờ cho tuần này.'
    FROM Cap c
    LEFT JOIN #D a ON a.MaLop = c.MaLopA AND a.MaMon = c.MaMonA
    LEFT JOIN #D b ON b.MaLop = c.MaLopB AND b.MaMon = c.MaMonB
    WHERE (CASE WHEN ISNULL(a.Dm, 0) = 0 THEN 1 ELSE 0 END) <> (CASE WHEN ISNULL(b.Dm, 0) = 0 THEN 1 ELSE 0 END)
      AND EXISTS (SELECT 1 FROM tblTKB_Lop l WHERE l.MaLop = c.MaLopA AND l.Enable = 1)
      AND EXISTS (SELECT 1 FROM tblTKB_Lop l WHERE l.MaLop = c.MaLopB AND l.Enable = 1);

    -- 2) Tong tiet cua lop vuot so o hoc trong tuan
    INSERT #KQ
    SELECT 'LOI', N'Sức chứa lớp', d.MaLop,
           N'Lớp ' + d.MaLop + N' cần ' + CAST(d.Can AS NVARCHAR(5)) + N' tiết nhưng tuần này chỉ có ' + CAST(ISNULL(o.SoO, 0) AS NVARCHAR(5)) + N' ô học (đã trừ ngày nghỉ).',
           N'Giảm định mức tuần này hoặc kiểm tra lại ngày nghỉ của lớp.'
    FROM (SELECT MaLop, SUM(Dm) AS Can FROM #D WHERE MaMon <> 'SH' GROUP BY MaLop) d
    LEFT JOIN (SELECT MaLop, COUNT(*) AS SoO FROM #O GROUP BY MaLop) o ON o.MaLop = d.MaLop
    WHERE EXISTS (SELECT 1 FROM tblTKB_Lop l WHERE l.MaLop = d.MaLop AND l.Enable = 1 AND l.MaLop NOT LIKE '26%' AND LEN(l.MaLop) <= 5)
      AND d.Can > ISNULL(o.SoO, 0);

    -- 3) GV phai day nhieu tiet hon so o con ranh (bao ban + hop)
    SELECT DISTINCT g.MaGV, g.Thu, b.Buoi, t.Tiet
    INTO #BAN
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(g.Buoi, '') = '' OR g.Buoi = x.Buoi) b
    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) t
    WHERE g.Tuan = @Tuan
    UNION
    SELECT h.MaGV, h.Thu, h.Buoi, h.Tiet FROM dbo.fnTkbLichHopGV(@Tuan) h WHERE h.LoaiNhom <> 'KhoiCap23SH';

    ;WITH Tai AS (
        SELECT p.MaGV, SUM(p.Dm) AS Can, MAX(CASE WHEN l.Khoi >= '06' THEN 1 ELSE 0 END) AS CoCap23
        FROM #PC p INNER JOIN tblTKB_Lop l ON l.MaLop = p.MaLop
        WHERE p.MaGV LIKE 'NV%' AND p.MaMon <> 'SH' AND l.Enable = 1 AND l.MaLop NOT LIKE '26%'
        GROUP BY p.MaGV
    ), Ranh AS (
        SELECT t.MaGV, t.Can,
               (CASE WHEN t.CoCap23 = 1 THEN 45 ELSE 40 END)
               - (SELECT COUNT(*) FROM #BAN b WHERE b.MaGV = t.MaGV AND b.Thu BETWEEN 2 AND 6
                  AND (b.Tiet <= 4 OR (b.Tiet = 5 AND b.Buoi = 'Sang' AND t.CoCap23 = 1))) AS Ranh
        FROM Tai t
    )
    INSERT #KQ
    SELECT CASE WHEN r.Can > r.Ranh THEN 'LOI' ELSE 'CANHBAO' END, N'Giáo viên kín lịch',
           ISNULL(g.HoTen, r.MaGV) + N' (' + r.MaGV + N')',
           N'Phải dạy ' + CAST(r.Can AS NVARCHAR(5)) + N' tiết, còn ' + CAST(r.Ranh AS NVARCHAR(5)) + N' ô rảnh sau khi trừ báo bận và họp.',
           CASE WHEN r.Can > r.Ranh THEN N'Không thể xếp đủ: bớt báo bận/họp, hoặc chuyển bớt tiết cho GV khác.'
                ELSE N'Gần kín: dễ thiếu tiết, nên xem lại báo bận và họp.' END
    FROM Ranh r LEFT JOIN tblTKB_GiaoVien g ON g.MaGV = r.MaGV
    WHERE r.Can > r.Ranh - 2;

    -- 4) Luat so tiet/ngay khong con kha thi vi tuan bi cat ngay (vd Toan TH 1 tiet/ngay)
    ;WITH QT AS (
        SELECT q.MaMon, q.Khoi, TRY_CAST(JSON_VALUE(q.ThamSo, '$.soTiet') AS INT) AS SoTiet,
               TRY_CAST(JSON_VALUE(q.ThamSo, '$.tuan') AS INT) AS TuanQT
        FROM tblTKB_MonQuyTac q WHERE q.Enable = 1 AND q.LoaiQuyTac = 'MaxTietMoiNgay'
    ), QTTuan AS (
        SELECT a.MaMon, a.Khoi, a.SoTiet FROM QT a
        WHERE (a.TuanQT = @Tuan) OR (a.TuanQT IS NULL AND NOT EXISTS (SELECT 1 FROM QT b WHERE b.MaMon = a.MaMon AND ISNULL(b.Khoi, '') = ISNULL(a.Khoi, '') AND b.TuanQT = @Tuan))
    ), Ngay AS (
        SELECT MaLop, COUNT(DISTINCT Thu) AS SoNgay FROM #O GROUP BY MaLop
    )
    INSERT #KQ
    SELECT 'LOI', N'Luật tiết/ngày', d.MaLop + N' · ' + d.MaMon,
           N'Lớp ' + d.MaLop + N' cần ' + CAST(d.Dm AS NVARCHAR(5)) + N' tiết ' + d.MaMon + N' nhưng chỉ học ' + CAST(n.SoNgay AS NVARCHAR(5))
           + N' ngày, luật cho tối đa ' + CAST(q.SoTiet AS NVARCHAR(5)) + N' tiết/ngày.',
           N'Thêm quy tắc riêng tuần ' + CAST(@Tuan AS NVARCHAR(5)) + N' (tham số "tuan") nới số tiết/ngày, hoặc giảm định mức.'
    FROM #D d
    INNER JOIN tblTKB_Lop l ON l.MaLop = d.MaLop AND l.Enable = 1
    INNER JOIN QTTuan q ON q.MaMon = d.MaMon AND (q.Khoi IS NULL OR q.Khoi = l.Khoi)
    INNER JOIN Ngay n ON n.MaLop = d.MaLop
    WHERE q.SoTiet IS NOT NULL AND d.Dm > q.SoTiet * n.SoNgay;

    -- 5) Hai ma GV cung ten deu dang co phan cong
    INSERT #KQ
    SELECT 'CANHBAO', N'Trùng tên giáo viên', g.HoTen,
           N'Có ' + CAST(COUNT(DISTINCT g.MaGV) AS NVARCHAR(3)) + N' mã cùng tên đang có phân công tuần này: ' + STRING_AGG(g.MaGV, ', ') + N'.',
           N'Kiểm tra phân công có gán nhầm mã không (đã từng gây thiếu 13 tiết Sử).'
    FROM tblTKB_GiaoVien g
    WHERE g.Enable = 1 AND EXISTS (SELECT 1 FROM #PC p WHERE p.MaGV = g.MaGV)
    GROUP BY g.HoTen
    HAVING COUNT(DISTINCT g.MaGV) > 1;

    -- 6) Gio hop GVCN tieu hoc: so GV bo mon con ranh < so lop can lap
    ;WITH HopLop AS (
        SELECT l.MaLop, l.Khoi, h.Thu, h.Buoi, h.Tiet
        FROM tblTKB_Lop l INNER JOIN dbo.fnTkbLichHopGV(@Tuan) h ON h.MaGV = l.GVCN
        WHERE l.Enable = 1 AND l.Khoi < '06' AND LEN(l.MaLop) = 3 AND h.LoaiNhom <> 'KhoiCap23SH' AND h.Tiet <= 4
          AND EXISTS (SELECT 1 FROM #O o WHERE o.MaLop = l.MaLop AND o.Thu = h.Thu AND o.Buoi = h.Buoi AND o.Tiet = h.Tiet)
    ), O AS (
        SELECT h.Khoi, h.Thu, h.Buoi, h.Tiet, COUNT(DISTINCT h.MaLop) AS SoLop,
               (SELECT COUNT(DISTINCT p.MaGV) FROM #PC p INNER JOIN HopLop h2 ON h2.MaLop = p.MaLop AND h2.Thu = h.Thu AND h2.Buoi = h.Buoi AND h2.Tiet = h.Tiet
                INNER JOIN tblTKB_Lop l2 ON l2.MaLop = p.MaLop
                WHERE p.MaGV <> ISNULL(l2.GVCN, '') AND p.MaGV LIKE 'NV%'
                  AND NOT EXISTS (SELECT 1 FROM #BAN b WHERE b.MaGV = p.MaGV AND b.Thu = h.Thu AND b.Buoi = h.Buoi AND b.Tiet = h.Tiet)) AS SoGV
        FROM HopLop h GROUP BY h.Khoi, h.Thu, h.Buoi, h.Tiet
    )
    INSERT #KQ
    SELECT 'CANHBAO', N'Giờ họp tiểu học', N'Khối ' + Khoi + N' · T' + CAST(Thu AS NVARCHAR(2)) + N' ' + CASE WHEN Buoi = 'Sang' THEN N'sáng' ELSE N'chiều' END + N' tiết ' + CAST(Tiet AS NVARCHAR(2)),
           CAST(SoLop AS NVARCHAR(3)) + N' lớp có GVCN họp, chỉ ' + CAST(SoGV AS NVARCHAR(3)) + N' GV bộ môn của các lớp này còn rảnh để dạy thay giờ đó.',
           N'Dời giờ họp, hoặc chừa thêm GV bộ môn (đôi TA, GDTC song song) cho giờ này.'
    FROM O WHERE SoGV < SoLop;

    -- 7) Lich hop tuan
    IF NOT EXISTS (SELECT 1 FROM tblTKB_LichHopGV_Tuan WHERE Tuan = @Tuan)
        INSERT #KQ VALUES ('CANHBAO', N'Lịch họp', N'Tuần ' + CAST(@Tuan AS NVARCHAR(5)),
            N'Chưa nhập lịch họp riêng cho tuần này, hệ thống đang dùng lịch họp cố định.', N'Nhập lịch họp tuần nếu tuần này họp khác thường lệ.');
    INSERT #KQ
    SELECT 'CANHBAO', N'Lịch họp', ISNULL(g.HoTen, x.MaGV) + N' · T' + CAST(x.Thu AS NVARCHAR(2)) + N' ' + x.Buoi + N' tiết ' + CAST(x.Tiet AS NVARCHAR(2)),
           N'Có ' + CAST(x.SoNhom AS NVARCHAR(3)) + N' cuộc họp trùng giờ.', N'Kiểm tra lại lịch họp của giáo viên này.'
    FROM (SELECT MaGV, Thu, Buoi, Tiet, COUNT(DISTINCT MaNhom) AS SoNhom FROM dbo.fnTkbLichHopGV(@Tuan) WHERE LoaiNhom <> 'KhoiCap23SH' GROUP BY MaGV, Thu, Buoi, Tiet HAVING COUNT(DISTINCT MaNhom) > 1) x
    LEFT JOIN tblTKB_GiaoVien g ON g.MaGV = x.MaGV;

    -- 8) Thong tin: lop-mon doi dinh muc so voi tuan truoc
    ;WITH Truoc AS (
        SELECT pc.MaLop, pc.MaMon, SUM(pc.SoTietChuanTuan) AS Dm
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = 'HK1' AND pc.SoTietChuanTuan > 0
          AND (pc.TuanApDungTu IS NULL OR pc.TuanApDungTu <= @Tuan - 1) AND (pc.TuanApDungDen IS NULL OR pc.TuanApDungDen >= @Tuan - 1)
          AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN (@Tuan - 1) % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    )
    INSERT #KQ
    SELECT 'THONGTIN', N'Định mức đổi', N'Khối ' + LEFT(COALESCE(a.MaLop, b.MaLop), 2),
           CAST(COUNT(*) AS NVARCHAR(5)) + N' lớp–môn đổi số tiết so với tuần ' + CAST(@Tuan - 1 AS NVARCHAR(5)) + N' (tăng ' + CAST(SUM(CASE WHEN ISNULL(a.Dm, 0) > ISNULL(b.Dm, 0) THEN 1 ELSE 0 END) AS NVARCHAR(5))
           + N', giảm ' + CAST(SUM(CASE WHEN ISNULL(a.Dm, 0) < ISNULL(b.Dm, 0) THEN 1 ELSE 0 END) AS NVARCHAR(5)) + N').',
           N'Xem tab Tuần mới để biết số ô phải xếp lại.'
    FROM #D a FULL OUTER JOIN Truoc b ON b.MaLop = a.MaLop AND b.MaMon = a.MaMon
    WHERE ISNULL(a.Dm, 0) <> ISNULL(b.Dm, 0) AND COALESCE(a.MaLop, b.MaLop) NOT LIKE '26%' AND COALESCE(a.MaMon, b.MaMon) <> 'SH'
    GROUP BY LEFT(COALESCE(a.MaLop, b.MaLop), 2);

    SELECT MucDo, Nhom, DoiTuong, MoTa, GoiY FROM #KQ
    ORDER BY CASE MucDo WHEN 'LOI' THEN 1 WHEN 'CANHBAO' THEN 2 ELSE 3 END, Nhom, DoiTuong;
END
