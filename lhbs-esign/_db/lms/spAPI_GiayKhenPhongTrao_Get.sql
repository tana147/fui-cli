
CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTrao_Get]
    @NienKhoa INT
  , @HocKy INT
  , @KhoiID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT p.PhongTraoID
         , p.TenPhongTrao
         , p.LoaiMau
         , CASE p.LoaiMau
             WHEN 1 THEN N'Mẫu 1 (Ghi tay)'
             WHEN 2 THEN N'Mẫu 2 (In sẵn tên HS)'
             WHEN 3 THEN N'Mẫu 3 (Trống tên HS)'
             WHEN 4 THEN N'Mẫu Tập thể (Giấy khen tập thể)'
             ELSE N'Chưa xác định'
           END AS TenLoaiMau
         /* Các field này là projection tương thích; dữ liệu gốc mới nằm ở DongJson. */
         , COALESCE(dvi.NoiDung, p.DanhHieu_VI) AS DanhHieu_VI
         , COALESCE(den.NoiDung, p.DanhHieu_EN) AS DanhHieu_EN
         , COALESCE(dyear.NoiDung, p.NamHoc) AS NamHoc
         , p.NgayCap_VI
         , p.NgayCap_EN
         , p.SoQuyetDinh
         , p.KhoiID
         , p.HocKy
         , p.NienKhoa
         , p.GhiChu
         , COALESCE(g.CacGiai_VI, N'') AS CacGiai_VI
         , COALESCE(c.SoLuongHocSinh, 0) AS SoLuongHocSinh
         , COALESCE(lines.DongJson, N'[]') AS DongJson
    FROM dbo.tblGiayKhenPhongTrao p
    OUTER APPLY
    (
        SELECT COUNT(1) AS SoLuongHocSinh
        FROM dbo.tblGiayKhenPhongTraoChiTiet ct
        WHERE ct.PhongTraoID = p.PhongTraoID
          AND ct.Enable = 1
    ) c
    OUTER APPLY
    (
        SELECT STRING_AGG(gt.TenGiai_VI, N', ') WITHIN GROUP (ORDER BY gt.ThuTu) AS CacGiai_VI
        FROM dbo.tblGiayKhenPhongTraoGiai gt
        WHERE gt.PhongTraoID = p.PhongTraoID
          AND gt.Enable = 1
    ) g
    OUTER APPLY
    (
        SELECT TOP 1 d.NoiDung
        FROM dbo.tblGiayKhenPhongTraoDong d
        WHERE d.PhongTraoID = p.PhongTraoID
          AND d.Enable = 1
          AND d.MaDong = N'DANH_HIEU_VI'
        ORDER BY d.ThuTuDong, d.DongID
    ) dvi
    OUTER APPLY
    (
        SELECT TOP 1 d.NoiDung
        FROM dbo.tblGiayKhenPhongTraoDong d
        WHERE d.PhongTraoID = p.PhongTraoID
          AND d.Enable = 1
          AND d.MaDong = N'DANH_HIEU_EN'
        ORDER BY d.ThuTuDong, d.DongID
    ) den
    OUTER APPLY
    (
        SELECT TOP 1 d.NoiDung
        FROM dbo.tblGiayKhenPhongTraoDong d
        WHERE d.PhongTraoID = p.PhongTraoID
          AND d.Enable = 1
          AND d.MaDong = N'NAM_HOC'
        ORDER BY d.ThuTuDong, d.DongID
    ) dyear
    OUTER APPLY
    (
        SELECT
        (
            SELECT d.DongID, d.ThuTuDong, d.TenDong, d.MaDong, d.NgonNgu,
                   d.NoiDung, d.KieuDuLieu, d.BatBuoc, d.Enable
            FROM dbo.tblGiayKhenPhongTraoDong d
            WHERE d.PhongTraoID = p.PhongTraoID
              AND d.Enable = 1
            ORDER BY d.ThuTuDong, d.DongID
            FOR JSON PATH
        ) AS DongJson
    ) lines
    WHERE p.Enable = 1
      AND p.NienKhoa = @NienKhoa
      AND p.HocKy = @HocKy
      AND (@KhoiID = 0 OR p.KhoiID = 0 OR p.KhoiID = @KhoiID)
    ORDER BY p.PhongTraoID DESC;
END;
