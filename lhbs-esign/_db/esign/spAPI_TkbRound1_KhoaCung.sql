CREATE PROCEDURE spAPI_TkbRound1_KhoaCung
    @Khoi VARCHAR(50) = '',
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @RunID INT = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN: Round 1 — khoa cung TUYET DOI, KHONG qua CP-SAT (khong dung solver) — SH (sinh hoat
    -- chu nhiem cap 2-3) + HDTN1/chao co (tiet dau tuan). Tao/dung RunID moi, toan truong. Chay DAU
    -- TIEN, truoc moi round khac.
    -- 2026-09-12 (theo de xuat UI 4-Round, nguoi dung muon dung lai xem tung buoc): Round 1 = khoa
    -- cung nhung gio KHONG THE THUONG LUONG — TRUOC DAY cac buoc nay (SH, HDTN1/chao co) chi chay am
    -- tham BEN TRONG spAPI_TkbChayAuto, khong xem duoc ket qua rieng truoc khi goi CP-SAT. SP nay tach
    -- ra doc lap, KHONG goi solver, chi tao/dung RunID + chay dung 2 khoi khoa da co (sao chep y het
    -- logic tu spAPI_TkbChayAuto — nhanh @ChiGV IS NULL, vi Round 1 luon danh cho TOAN BO GV) + tra ve
    -- thong ke % de nguoi dung xem truoc khi qua Round 2.
    -- LUU Y: day la BAN SAO logic, khong phai goi lai spAPI_TkbChayAuto — neu sau nay sua cach khoa
    -- SH/HDTN1 ben spAPI_TkbChayAuto thi PHAI sua dong bo o day, neu khong 2 noi se lech nhau.

    IF @RunID IS NULL OR NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
        VALUES (SYSUTCDATETIME(), CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END,
                0, N'Round1_DaKhoa', @sys_UserID, @TuanHienTai, 1);
        SET @RunID = SCOPE_IDENTITY();
    END

    -- Auto-khoa SH — y het nhanh @ChiGV IS NULL trong spAPI_TkbChayAuto.
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT DISTINCT @RunID, pc.MaLop, ISNULL(ov.Thu, 6), ISNULL(ov.Buoi, N'Chieu'), ISNULL(ov.Tiet, 4), 'SH', pc.MaGV, NULL, 0
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_SH_OverrideSlot ov ON ov.MaLop = pc.MaLop AND ov.Enable = 1
    WHERE pc.Enable = 1 AND pc.MaMon = 'SH'
      -- 2026-10-14: loc theo tuan (dong SH tat rieng tuan 13 cho 06A/08D van bi khoa vi thieu loc)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'SH'
      );

    -- Auto-khoa HDTN1 ("sinh hoat theo khoi/chao co") — y het spAPI_TkbChayAuto.
    -- SUA 2026-09-21: chi lich rieng theo tuan, KHONG fallback bang co dinh.
    ;WITH ChaoCoResolved AS (
        SELECT cct.Khoi, cct.Thu, cct.Buoi, cct.Tiet
        FROM tblTKB_ChaoCoKhoi_Tuan cct
        WHERE cct.Enable = 1 AND cct.Tuan = @TuanHienTai
    )
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT DISTINCT @RunID, pc.MaLop, cr.Thu, cr.Buoi, cr.Tiet, 'HDTN1', pc.MaGV, NULL, 0
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    INNER JOIN ChaoCoResolved cr ON cr.Khoi = l.Khoi
    WHERE pc.Enable = 1 AND pc.MaMon = 'HDTN1'
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
      -- SUA 2026-09-12: doi tu "NOT EXISTS (...MaMon='HDTN1')" sang kiem tra DUNG slot — 1 lop gio co
      -- THE co 2 dong HDTN1 (chao co + Thu6, xem doan INSERT ben duoi), y het spAPI_TkbChayAuto.sql.
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'HDTN1'
            AND k.Thu = cr.Thu AND k.Buoi = cr.Buoi AND k.Tiet = cr.Tiet
      );

    -- Auto-khoa HDTN1 tiet CUOI NGAY Thu 6 (2026-09-12, theo de xuat nguoi dung "gan mac dinh, chi GV
    -- doi lich dac thu moi sua tay") — y het spAPI_TkbChayAuto.sql: mac dinh Thu=6/Chieu/Tiet=4, override
    -- qua tblTKB_HDTN1_OverrideSlot, chi ap dung khi SoTietChuanTuan > 1 (Tieu hoc).
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT DISTINCT @RunID, pc.MaLop, ISNULL(ov.Thu, 6), ISNULL(ov.Buoi, N'Chieu'), ISNULL(ov.Tiet, 4), 'HDTN1', pc.MaGV, NULL, 0
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_HDTN1_OverrideSlot ov ON ov.MaLop = pc.MaLop AND ov.Enable = 1
        -- 2026-10-07: override theo tuan (Tuan = tuan dang xep) uu tien hon override chung (Tuan NULL)
        AND (ov.Tuan = @TuanHienTai OR (ov.Tuan IS NULL AND NOT EXISTS (SELECT 1 FROM tblTKB_HDTN1_OverrideSlot o2
             WHERE o2.MaLop = pc.MaLop AND o2.Enable = 1 AND o2.Tuan = @TuanHienTai)))
    WHERE pc.Enable = 1 AND pc.MaMon = 'HDTN1' AND pc.SoTietChuanTuan > 1
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'HDTN1'
            AND k.Thu = ISNULL(ov.Thu, 6) AND k.Buoi = ISNULL(ov.Buoi, N'Chieu') AND k.Tiet = ISNULL(ov.Tiet, 4)
      );

    -- O co dinh theo tuan (2026-10-14, tblTKB_OCoDinh_Tuan): mon hoc dat san truoc khi xep, vd GDDP khoi 8
    -- tuan 13 (19-21/10) lap kin T2-T4 — khoa cung nhu SH/HDTN1, cac mon khac tu dong khong vao duoc.
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT @RunID, o.MaLop, o.Thu, o.Buoi, o.Tiet, o.MaMon, o.MaGV, NULL, 0
    FROM tblTKB_OCoDinh_Tuan o
    INNER JOIN tblTKB_Lop l ON l.MaLop = o.MaLop
    WHERE o.Enable = 1 AND o.Tuan = @TuanHienTai
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = o.MaLop
                      AND k.Thu = o.Thu AND k.Buoi = o.Buoi AND k.Tiet = o.Tiet);

    -- Khoa het moi dong Round 1 vua chen (SH+HDTN1) — day la "khong the thuong luong", phai nam trong
    -- tblTKB_KetQuaXep_Khoa ngay tu dau de cac buoc PhanConLai/Round2/Round4 sau nay khong bao gio dong.
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
    SELECT k.ID FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
    WHERE k.RunID = @RunID AND kh.KetQuaXepID IS NULL;

    -- Thong ke: tong so tiet CAN xep (~dung cong thuc NhuCau that su se gui CP-SAT, tru trung ENG1/
    -- TANN/SU nhieu GV luan phien chi tinh 1 lan) so voi so tiet DA khoa o Round 1 (SH+HDTN1).
    DECLARE @TongSoTiet INT, @SoTietDaKhoa INT;

    ;WITH PCGDLoc AS (
        SELECT pc.*, l.Khoi,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1','TANN','SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    )
    SELECT @TongSoTiet = SUM(SoTietChuanTuan) FROM PCGDLoc WHERE MaMon NOT IN ('ENG1','TANN','SU') OR rn = 1;

    SELECT @SoTietDaKhoa = COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon IN ('SH','HDTN1');

    UPDATE tblTKB_ChayAutoLog SET SoNhuCau = @TongSoTiet WHERE RunID = @RunID;

    SELECT @RunID AS RunID, @TongSoTiet AS TongSoTiet, @SoTietDaKhoa AS SoTietDaKhoa,
           CAST(ROUND(100.0 * @SoTietDaKhoa / NULLIF(@TongSoTiet, 0), 1) AS DECIMAL(5,1)) AS PhanTramDaKhoa;
END