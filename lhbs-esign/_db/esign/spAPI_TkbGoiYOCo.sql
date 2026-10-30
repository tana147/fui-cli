CREATE PROCEDURE spAPI_TkbGoiYOCo
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(20),
    @MaGV VARCHAR(15),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-10-06 (muc tieu: auto ~90%, phan con lai SAP TAY co ho tro): goi y O DAT cho 1 tiet con thieu
    -- (lop, mon, GV) — tu tinh, khong AI, nhanh. Moi dong = 1 phuong an doc lap, bam la ap dung
    -- (spAPI_TkbGoiYOCoApDung). Khac spAPI_TkbGoiYChuoi cu: (1) co tinh lich BAO BAN GV theo tuan,
    -- (2) them loai "doi phia LOP" (doi 1 tiet khac cua chinh lop sang o khac — kieu ket pho bien nhat:
    -- o trong cua lop khong trung o ranh cua GV), (3) liet ke ca phuong an PHA LUAT kem ly do de nguoi
    -- xep tu quyet. KHONG bao gio de xuat trung lich vat ly (lop 2 tiet / GV 2 noi cung luc).
    --   MucDo 1 TRUC_TIEP : lop + GV cung ranh, GV khong bao ban
    --   MucDo 2 DOI_GV    : lop ranh, GV dang day lop khac o do -> chuyen tiet do cua GV sang o khac hop le
    --   MucDo 2 DOI_LOP   : GV ranh, lop dang hoc mon khac o do -> chuyen tiet do cua lop sang o khac hop le
    --   MucDo 3 PHA_LUAT  : lop + GV cung ranh nhung GV da bao ban (ghi ro ly do), hoac o Sinh hoat T6 chieu tiet 4
    --   MucDo 4 THAY_THE  : bo 1 tiet khac cua lop ra (tiet do quay ve danh sach con thieu) de dat tiet nay
    -- Khong dong toi: SH, HDTN1, HOP, KHOAPHONG, dong khong phai GV that (cum tach), 1 nua cua tiet doi.
    DECLARE @Tuan INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    DECLARE @Khoi VARCHAR(4) = (SELECT Khoi FROM tblTKB_Lop WHERE MaLop = @MaLop);

    CREATE TABLE #K (ID INT PRIMARY KEY, MaLop VARCHAR(10), Khoi VARCHAR(4), Thu INT, Buoi VARCHAR(10), Tiet INT, MaMon VARCHAR(20), MaGV VARCHAR(15), Movable BIT);
    INSERT INTO #K (ID, MaLop, Khoi, Thu, Buoi, Tiet, MaMon, MaGV, Movable)
    SELECT k.ID, k.MaLop, l.Khoi, k.Thu, k.Buoi, k.Tiet, k.MaMon, k.MaGV, 1
    FROM tblTKB_KetQuaXep k LEFT JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    WHERE k.RunID = @RunID;
    CREATE INDEX IX_K_Lop ON #K (MaLop, Thu, Buoi, Tiet);
    CREATE INDEX IX_K_GV ON #K (MaGV, Thu, Buoi, Tiet);

    UPDATE k SET Movable = 0 FROM #K k
    WHERE k.MaMon IN ('SH', 'HDTN1', 'HOP', 'KHOAPHONG')
       OR NOT EXISTS (SELECT 1 FROM tblTKB_GiaoVien g WHERE g.MaGV = k.MaGV)
       OR EXISTS (SELECT 1 FROM #K p WHERE p.MaLop = k.MaLop AND p.MaMon = k.MaMon AND p.MaGV = k.MaGV
                  AND p.Thu = k.Thu AND p.Buoi = k.Buoi AND ABS(p.Tiet - k.Tiet) = 1);

    -- O hop le theo khoi = o ma it nhat 1 lop cung khoi dang co tiet trong RunID nay (dung so tiet that tung buoi).
    CREATE TABLE #SlotKhoi (Khoi VARCHAR(4), Thu INT, Buoi VARCHAR(10), Tiet INT, PRIMARY KEY (Khoi, Thu, Buoi, Tiet));
    INSERT INTO #SlotKhoi SELECT DISTINCT Khoi, Thu, Buoi, Tiet FROM #K WHERE Khoi IS NOT NULL AND Tiet BETWEEN 1 AND 5;

    -- Lich bao ban GV tuan nay (trai ra tung tiet).
    CREATE TABLE #Cam (MaGV VARCHAR(15), Thu INT, Buoi VARCHAR(10), Tiet INT, LyDo NVARCHAR(300), PRIMARY KEY (MaGV, Thu, Buoi, Tiet));
    INSERT INTO #Cam (MaGV, Thu, Buoi, Tiet, LyDo)
    SELECT g.MaGV, g.Thu, b.Buoi, t.Tiet, MAX(ISNULL(g.LyDo, N'GV báo bận'))
    FROM tblTKB_GVCamTuyetDoi_Tuan g
    CROSS APPLY (VALUES ('Sang'), ('Chieu')) b(Buoi)
    CROSS APPLY (VALUES (1), (2), (3), (4), (5)) t(Tiet)
    WHERE g.Tuan = @Tuan AND (ISNULL(g.Buoi, '') = '' OR g.Buoi = b.Buoi) AND (g.Tiet IS NULL OR g.Tiet = t.Tiet)
    GROUP BY g.MaGV, g.Thu, b.Buoi, t.Tiet;

    CREATE TABLE #Out (MucDo INT, LoaiGoiY VARCHAR(20), Thu INT, Buoi VARCHAR(10), Tiet INT,
                       IDChuyen INT NULL, Thu2 INT NULL, Buoi2 VARCHAR(10) NULL, Tiet2 INT NULL, MoTa NVARCHAR(500));

    -- 1) TRUC_TIEP
    INSERT INTO #Out (MucDo, LoaiGoiY, Thu, Buoi, Tiet, MoTa)
    SELECT 1, 'TRUC_TIEP', s.Thu, s.Buoi, s.Tiet, N'Xếp thẳng — lớp và GV cùng rảnh'
    FROM #SlotKhoi s
    WHERE s.Khoi = @Khoi
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = @MaLop AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = @MaGV AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = @MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet);

    -- 2) DOI_GV: lop ranh, GV dang day 1 lop khac (g) o do; g chuyen sang s2 hop le cho khoi cua g,
    --    lop cua g ranh, GV ranh + khong bao ban o s2.
    INSERT INTO #Out (MucDo, LoaiGoiY, Thu, Buoi, Tiet, IDChuyen, Thu2, Buoi2, Tiet2, MoTa)
    SELECT 2, 'DOI_GV', s.Thu, s.Buoi, s.Tiet, g.ID, s2.Thu, s2.Buoi, s2.Tiet,
           N'Chuyển tiết ' + g.MaMon + N' lớp ' + g.MaLop + N' (cùng GV) sang Thứ ' + CAST(s2.Thu AS NVARCHAR(2))
           + CASE s2.Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(s2.Tiet AS NVARCHAR(2)) + N', rồi xếp vào ô này'
    FROM #SlotKhoi s
    INNER JOIN #K g ON g.MaGV = @MaGV AND g.Thu = s.Thu AND g.Buoi = s.Buoi AND g.Tiet = s.Tiet AND g.Movable = 1
    CROSS APPLY (
        SELECT TOP 1 t.Thu, t.Buoi, t.Tiet FROM #SlotKhoi t
        WHERE t.Khoi = g.Khoi AND NOT (t.Thu = s.Thu AND t.Buoi = s.Buoi AND t.Tiet = s.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = g.MaLop AND x.Thu = t.Thu AND x.Buoi = t.Buoi AND x.Tiet = t.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = @MaGV AND x.Thu = t.Thu AND x.Buoi = t.Buoi AND x.Tiet = t.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = @MaGV AND c.Thu = t.Thu AND c.Buoi = t.Buoi AND c.Tiet = t.Tiet)
        ORDER BY t.Thu, t.Buoi DESC, t.Tiet
    ) s2
    WHERE s.Khoi = @Khoi
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = @MaLop AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = @MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet);

    -- 3) DOI_LOP: GV ranh + khong bao ban o s, lop dang hoc mon khac (b, GV Y) o s; b chuyen sang s2 ma
    --    lop ranh, Y ranh + khong bao ban.
    INSERT INTO #Out (MucDo, LoaiGoiY, Thu, Buoi, Tiet, IDChuyen, Thu2, Buoi2, Tiet2, MoTa)
    SELECT 2, 'DOI_LOP', s.Thu, s.Buoi, s.Tiet, b.ID, s2.Thu, s2.Buoi, s2.Tiet,
           N'Chuyển tiết ' + b.MaMon + N' (GV ' + ISNULL(gv.HoTen, b.MaGV) + N') của lớp sang Thứ ' + CAST(s2.Thu AS NVARCHAR(2))
           + CASE s2.Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(s2.Tiet AS NVARCHAR(2)) + N', rồi xếp vào ô này'
    FROM #SlotKhoi s
    INNER JOIN #K b ON b.MaLop = @MaLop AND b.Thu = s.Thu AND b.Buoi = s.Buoi AND b.Tiet = s.Tiet AND b.Movable = 1
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = b.MaGV
    CROSS APPLY (
        SELECT TOP 1 t.Thu, t.Buoi, t.Tiet FROM #SlotKhoi t
        WHERE t.Khoi = @Khoi AND NOT (t.Thu = s.Thu AND t.Buoi = s.Buoi AND t.Tiet = s.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = @MaLop AND x.Thu = t.Thu AND x.Buoi = t.Buoi AND x.Tiet = t.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = b.MaGV AND x.Thu = t.Thu AND x.Buoi = t.Buoi AND x.Tiet = t.Tiet)
          AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = b.MaGV AND c.Thu = t.Thu AND c.Buoi = t.Buoi AND c.Tiet = t.Tiet)
        ORDER BY t.Thu, t.Buoi DESC, t.Tiet
    ) s2
    WHERE s.Khoi = @Khoi
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = @MaGV AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = @MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet);

    -- 4) PHA_LUAT: lop + GV cung ranh nhung GV bao ban
    INSERT INTO #Out (MucDo, LoaiGoiY, Thu, Buoi, Tiet, MoTa)
    SELECT 3, 'PHA_LUAT', s.Thu, s.Buoi, s.Tiet, N'Phá luật — GV báo bận: ' + c.LyDo
    FROM #SlotKhoi s
    INNER JOIN #Cam c ON c.MaGV = @MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet
    WHERE s.Khoi = @Khoi
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = @MaLop AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = @MaGV AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet);

    -- 5) THAY_THE (phuong an cuoi): GV ranh + khong bao ban o s, lop dang hoc mon khac (b, dong duoc) — bo b ra (b quay
    --    ve danh sach con thieu) roi dat tiet nay vao. Nguoi xep tu can nhac mon nao it quan trong hon.
    INSERT INTO #Out (MucDo, LoaiGoiY, Thu, Buoi, Tiet, IDChuyen, MoTa)
    SELECT 4, 'THAY_THE', s.Thu, s.Buoi, s.Tiet, b.ID,
           N'Thay thế — bỏ tiết ' + b.MaMon + N' (GV ' + ISNULL(gv.HoTen, b.MaGV) + N') ra, tiết đó chuyển sang danh sách còn thiếu'
    FROM #SlotKhoi s
    INNER JOIN #K b ON b.MaLop = @MaLop AND b.Thu = s.Thu AND b.Buoi = s.Buoi AND b.Tiet = s.Tiet AND b.Movable = 1 AND b.MaMon <> @MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = b.MaGV
    WHERE s.Khoi = @Khoi
      AND NOT EXISTS (SELECT 1 FROM #K x WHERE x.MaGV = @MaGV AND x.Thu = s.Thu AND x.Buoi = s.Buoi AND x.Tiet = s.Tiet)
      AND NOT EXISTS (SELECT 1 FROM #Cam c WHERE c.MaGV = @MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet);

    -- O Sinh hoat cap 2-3 (Thu 6 chieu tiet 4): solver danh rieng cho GVCN — van liet ke (lich that doi khi dung, vd 08C
    -- tuan 8 xep Van o day vi SH cua lop o ca sang) nhung ha xuong "pha luat" kem ly do.
    IF @Khoi >= '06'
        UPDATE #Out SET MucDo = 3, LoaiGoiY = CASE WHEN LoaiGoiY = 'TRUC_TIEP' THEN 'PHA_LUAT' ELSE LoaiGoiY END,
               MoTa = N'Phá luật — ô dành cho Sinh hoạt lớp (T6 chiều tiết 4); ' + MoTa
        WHERE Thu = 6 AND Buoi = 'Chieu' AND Tiet = 4 AND MucDo < 3;

    -- Canh bao lap mon trong ngay (vd Toan tieu hoc toi da 1 tiet/ngay, mon le khong nen 2 tiet/ngay).
    UPDATE o SET MoTa = o.MoTa + N' · Lưu ý: lớp đã có ' + @MaMon + N' trong ngày này'
    FROM #Out o
    WHERE EXISTS (SELECT 1 FROM #K x WHERE x.MaLop = @MaLop AND x.MaMon = @MaMon AND x.Thu = o.Thu AND x.ID <> ISNULL(o.IDChuyen, -1));

    SELECT TOP 40 o.MucDo, o.LoaiGoiY,
           CASE o.MucDo WHEN 1 THEN N'Xếp thẳng' WHEN 2 THEN N'Đổi 1 bước' WHEN 3 THEN N'Phá luật' ELSE N'Thay thế' END AS NhanMucDo,
           o.Thu, o.Buoi, o.Tiet,
           N'Thứ ' + CAST(o.Thu AS NVARCHAR(2)) + CASE o.Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(o.Tiet AS NVARCHAR(2)) AS ONhan,
           o.IDChuyen, o.Thu2, o.Buoi2, o.Tiet2, o.MoTa,
           @MaLop AS MaLop, @MaMon AS MaMon, @MaGV AS MaGV
    FROM #Out o
    ORDER BY o.MucDo, o.Thu, CASE o.Buoi WHEN 'Sang' THEN 0 ELSE 1 END, o.Tiet, o.LoaiGoiY;
END
