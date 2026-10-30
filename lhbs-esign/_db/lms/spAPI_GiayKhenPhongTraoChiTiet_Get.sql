CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoChiTiet_Get]
    @PhongTraoID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT c.ChiTietID
         , c.PhongTraoID
         , c.HocSinhID
         , c.HoTen
         , c.TenLop
         , c.LopID
         , c.KhoiID
         , c.VaoSo
         , c.SoQuyetDinhVaKhenThuong
         , ISNULL(NULLIF(c.DanhHieu_VI, ''), COALESCE(dvi.NoiDung, p.DanhHieu_VI)) AS DanhHieu_VI
         , ISNULL(NULLIF(c.DanhHieu_EN, ''), COALESCE(den.NoiDung, p.DanhHieu_EN)) AS DanhHieu_EN
         , COALESCE(dyear.NoiDung, p.NamHoc) AS NamHoc
         , p.NgayCap_VI
         , p.NgayCap_EN
         , p.SoQuyetDinh
         , p.LoaiMau
         , c.Is_DaIn
         , COALESCE(lines.DongJson, N'[]') AS DongJson
    FROM dbo.tblGiayKhenPhongTraoChiTiet c
    INNER JOIN dbo.tblGiayKhenPhongTrao p ON p.PhongTraoID = c.PhongTraoID
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
    WHERE c.Enable = 1
      AND c.PhongTraoID = @PhongTraoID
    ORDER BY c.VaoSo, c.KhoiID, c.TenLop, c.HoTen, c.ChiTietID;
END
