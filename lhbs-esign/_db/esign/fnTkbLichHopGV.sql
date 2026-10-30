CREATE FUNCTION dbo.fnTkbLichHopGV (@Tuan INT)
RETURNS TABLE
AS
RETURN (
    -- 2026-10-07: GOM 1 CHO lich hop theo GV (truoc day CTE GVNhom bi lap 3 noi: spAPI_TkbChayAuto x2 +
    -- spAPI_TkbChayAutoTrangThai). Lich hop THAT thay doi theo tuan (lich tay tuan 8 vs 9 khac nhau o 43 GV),
    -- nen: neu tblTKB_LichHopGV_Tuan co dong cho @Tuan -> dung DUNG lich hop that cua tuan do (thay toan bo
    -- lich hop co dinh), CHI giu khoa SH cap 2-3 (KhoiCap23SH — bao ve tiet SH, khong phai cuoc hop that).
    -- Khong co dong nao cho @Tuan -> giu nguyen lich hop co dinh tblTKB_LichHopCoDinh nhu cu.
    -- Cot: MaGV, MaNhom (MaLop hien thi dong HOP), LoaiNhom, Thu, Buoi, Tiet, Cung (1 = hop khoi tieu hoc, cung).
    WITH GVNhom AS (
        SELECT MaGV, 'TUNHIEN' AS MaNhom, 'To' AS LoaiNhom FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ tự nhiên%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'NGUVAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ ngữ văn%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'XAHOI', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ xã hội%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'HDTNHN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Hoạt động trải nghiệm%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TOAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Toán%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TDANMT', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ thể dục - Quốc phòng - Nghệ thuật%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATIEUHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối Tiểu Học%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATRUNGHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối THCS%' AND LaThinhGiang = 0
        UNION ALL SELECT DISTINCT l.GVCN, l.Khoi, 'KhoiTH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND l.GVCN IS NOT NULL
        UNION ALL SELECT DISTINCT l.GVCN, 'CAP23SH', 'KhoiCap23SH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('06','07','08','09','10','11','12') AND l.GVCN IS NOT NULL
        UNION ALL SELECT MaGV, 'KT', 'KhoiTruong' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Khối trưởng%'
    ),
    CoDinh AS (
        SELECT gn.MaGV, gn.MaNhom, gn.LoaiNhom, lh.Thu, lh.Buoi, TRY_CAST(s.value AS INT) AS Tiet
        FROM tblTKB_LichHopCoDinh lh
        INNER JOIN GVNhom gn ON gn.LoaiNhom = lh.LoaiNhom AND gn.MaNhom = lh.MaNhom
        CROSS APPLY STRING_SPLIT(lh.TietList, ',') s
        WHERE lh.Enable = 1
    ),
    CoTuan AS (
        SELECT CASE WHEN EXISTS (SELECT 1 FROM tblTKB_LichHopGV_Tuan WHERE Tuan = @Tuan) THEN 1 ELSE 0 END AS Co
    )
    SELECT c.MaGV, c.MaNhom, c.LoaiNhom, c.Thu, c.Buoi, c.Tiet, CASE WHEN c.LoaiNhom = 'KhoiTH' THEN 1 ELSE 0 END AS Cung
    FROM CoDinh c CROSS JOIN CoTuan ct
    WHERE ct.Co = 0 OR c.LoaiNhom = 'KhoiCap23SH'
    UNION ALL
    SELECT w.MaGV, ISNULL(w.MaNhom, 'HOP'), 'Tuan', w.Thu, w.Buoi, w.Tiet, CAST(w.Cung AS INT)
    FROM tblTKB_LichHopGV_Tuan w
    -- 2026-10-08: dong danh dau Thu=0 = "tuan nay KHONG hop" (vd tuan 12 giua ky) — van bat co CoTuan
    -- (bo lich hop co dinh) nhung khong sinh o ban nao.
    WHERE w.Tuan = @Tuan AND w.Thu BETWEEN 2 AND 7
)