CREATE PROCEDURE spAPI_TkbPhongLopMonList
    @sys_UserID VARCHAR(50)
AS
BEGIN
    -- 2026-10-09: tab "Phong lop - mon" (theo doi/sua phong co dinh cua lop theo mon, tblTKB_PhongLopMon).
    -- 1 result set (tAPI chi doc tap dau), phan loai:
    --   GAN   : phong dang gan (MaLop, MaMon, MaPhong, Enable, GhiChu)
    --   PHONG : danh muc phong chuyen dung (MaPhong, TenPhong) — bo phong hoc cua lop
    --   CAN   : (lop, mon) co phan cong HK1 cua mon can phong nhung CHUA co phong dang bat
    SET NOCOUNT ON;
    SELECT 'GAN' AS Loai, p.MaLop, p.MaMon, p.MaPhong, CAST(p.Enable AS INT) AS Enable, p.GhiChu, CAST(NULL AS NVARCHAR(200)) AS TenPhong
    FROM tblTKB_PhongLopMon p
    UNION ALL
    SELECT 'PHONG', NULL, NULL, ph.MaPhong, 1, NULL, ph.TenPhong
    FROM tblTKB_PhongHoc ph
    WHERE ph.Enable = 1 AND NOT EXISTS (SELECT 1 FROM tblTKB_Lop l WHERE l.MaLop = ph.MaPhong)
    UNION ALL
    SELECT 'CAN', x.MaLop, x.MaMon, NULL, NULL, NULL, NULL
    FROM (SELECT DISTINCT pc.MaLop, pc.MaMon
          FROM tblTKB_PhanCongGiangDay pc
          INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop AND l.Enable = 1
          WHERE pc.Enable = 1 AND pc.HocKy = 'HK1' AND ISNULL(pc.SoTietChuanTuan, 0) > 0
            AND LEFT(pc.MaLop, 2) <> '26'
            AND (pc.MaMon IN ('TIN', 'MT', 'NHAC', 'SHTV', 'BOI')
                 OR (pc.MaMon = 'AI' AND LEN(pc.MaLop) = 3)
                 OR (pc.MaMon = 'STEM' AND LEFT(pc.MaLop, 2) IN ('06','07','08','09','10','11','12')))) x
    WHERE NOT EXISTS (SELECT 1 FROM tblTKB_PhongLopMon p WHERE p.MaLop = x.MaLop AND p.MaMon = x.MaMon AND p.Enable = 1);
END
