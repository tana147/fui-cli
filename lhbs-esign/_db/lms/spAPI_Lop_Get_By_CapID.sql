CREATE PROCEDURE [dbo].[spAPI_Lop_Get_By_CapID]
    @NienKhoa INT,
    @CapID INT,
    @SYS_USERID VARCHAR(9),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @sys_SystemRight = 5
    BEGIN
        DECLARE @KhoiID INT = (
            SELECT TOP 1 KhoiID
            FROM dbo.tblLop
            WHERE GVCN = @SYS_USERID AND NienKhoa = @NienKhoa
        );

        SELECT l.LopID, l.MaDonVi, l.TenLop, l.KhoiID, l.PhanBanID,
               l.TenKhoiPhanBan, l.NienKhoa, l.GVCN,
               gv.HoGV + ' ' + gv.TenGV AS Ten_GVCN,
               CAST(0 AS BIT) AS IsNhom,
               l.IsLopToHop
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblGiaoVien AS gv ON gv.GiaoVienID = l.GVCN
        WHERE l.CapID = @CapID AND l.KhoiID = @KhoiID
          AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
        UNION
        SELECT n.NhomID, n.MaDonVi, n.TenNhom, n.KhoiID, NULL,
               NULL, n.NienKhoa, n.GVCN, NULL,
               CAST(0 AS BIT), CAST(0 AS BIT)
        FROM dbo.tblNhom AS n
        WHERE n.CapID = @CapID AND n.KhoiID = @KhoiID
          AND n.Enable = 1 AND n.NienKhoa = @NienKhoa
          AND n.IsNhomLMS_GiaoBai = 0;
    END
    ELSE IF @sys_SystemRight IN (3, 7, 9)
    BEGIN
        SELECT l.LopID, l.MaDonVi, l.TenLop, l.KhoiID, l.PhanBanID,
               l.TenKhoiPhanBan, l.NienKhoa, l.GVCN,
               gv.HoGV + ' ' + gv.TenGV AS Ten_GVCN,
               CAST(0 AS BIT) AS IsNhom,
               l.IsLopToHop
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblGiaoVien AS gv ON gv.GiaoVienID = l.GVCN
        WHERE l.CapID = @CapID AND l.Enable = 1
          AND l.NienKhoa = @NienKhoa
        UNION
        SELECT n.NhomID, n.MaDonVi, n.TenNhom, n.KhoiID, NULL,
               NULL, n.NienKhoa, n.GVCN, NULL,
               CAST(1 AS BIT), CAST(0 AS BIT)
        FROM dbo.tblNhom AS n
        WHERE n.CapID = @CapID AND n.KhoiID = @KhoiID
          AND n.Enable = 1 AND n.NienKhoa = @NienKhoa
          AND n.IsNhomLMS_GiaoBai = 0;
    END
    ELSE
    BEGIN
        SELECT l.LopID, l.MaDonVi, l.TenLop, l.KhoiID, l.PhanBanID,
               l.TenKhoiPhanBan, l.NienKhoa, l.GVCN, l.CapID,
               gv.HoGV + ' ' + gv.TenGV AS Ten_GVCN,
               CAST(0 AS BIT) AS IsNhom,
               l.IsLopToHop
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblGiaoVien AS gv ON gv.GiaoVienID = l.GVCN
        WHERE l.CapID = @CapID AND l.GVCN = @SYS_USERID
          AND l.NienKhoa = @NienKhoa
        UNION
        SELECT n.NhomID, n.MaDonVi, n.TenNhom, n.KhoiID, NULL,
               NULL, n.NienKhoa, n.GVCN, n.CapID, NULL,
               CAST(1 AS BIT), CAST(0 AS BIT)
        FROM dbo.tblNhom AS n
        WHERE n.CapID = @CapID AND n.NienKhoa = @NienKhoa
          AND n.IsNhomLMS_GiaoBai = 0
        ORDER BY KhoiID;
    END
END;
GRANT EXECUTE ON [dbo].[spAPI_Lop_Get_By_CapID] TO [lmslhbs];