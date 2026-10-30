CREATE PROCEDURE spAPI_TkbKetQuaXepRunListKhaThi
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- TuanHienTai/TenTuan/TuanThuTrongThang (2026-08-28): xep lich la xep cho 1 TUAN cu the (dinh
    -- muc mon hoc thay doi theo tuan qua R18 — vd BTHT/STEM/JA), khong phai tuan nao cung giong
    -- nhau — nen UI PHAI hien ro dang xem/xep cho tuan nao, khong chi so RunID/Khoi/so tiet.
    ;WITH TuanThang AS (
        SELECT TuanTrongNam, ThangHoc, TenTuan,
               ROW_NUMBER() OVER (PARTITION BY ThangHoc ORDER BY TuanTrongNam) AS TuanThuTrongThang
        FROM tblTKB_Tuan
        WHERE Enable = 1
    )
    SELECT l.RunID, l.ThoiGianBatDau, l.Khoi, ISNULL(c.SoTiet, l.SoSlotDaXep) AS SoSlotDaXep, l.NgayApDungTu, l.TuanHienTai,
        t.TenTuan, t.TuanThuTrongThang, t.ThangHoc,
        -- 2026-10-10: lan chay da duoc 'Chot tuan' (tblTKB_TuanChot) — UI danh dau.
        CASE WHEN EXISTS (SELECT 1 FROM tblTKB_TuanChot tc WHERE tc.RunID = l.RunID) THEN 1 ELSE 0 END AS DaChot
    FROM tblTKB_ChayAutoLog l
    LEFT JOIN TuanThang t ON t.TuanTrongNam = l.TuanHienTai
    -- 2026-10-06: dem so tiet THAT trong RunID (log.SoSlotDaXep chi la so tiet cua job cuoi -> Chay nhanh
    -- 5 buoc chi hien so tiet buoc tieu hoc, gay hieu nham).
    OUTER APPLY (SELECT COUNT(*) AS SoTiet FROM tblTKB_KetQuaXep k WHERE k.RunID = l.RunID) c
    WHERE l.Enable = 1 AND l.KhaThi = 1
    ORDER BY l.RunID DESC;
END