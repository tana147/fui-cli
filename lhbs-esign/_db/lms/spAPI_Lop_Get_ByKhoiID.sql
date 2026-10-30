CREATE PROCEDURE [dbo].[spAPI_Lop_Get_ByKhoiID]
    @NienKhoa INT,
    @HocKi INT,
    @KhoiID INT,
    @SYS_USERID VARCHAR(9),
    @SYS_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Table_Lop TABLE (
        LopID VARCHAR(20),
        MaDonVi INT,
        TenLop NVARCHAR(200),
        KhoiID INT,
        GVCN NVARCHAR(200),
        IsNhom BIT,
        IsLopToHop BIT
    );

    IF @SYS_SystemRight IN (3, 5, 9)
    BEGIN
        INSERT INTO @Table_Lop (LopID, MaDonVi, TenLop, KhoiID, GVCN, IsNhom, IsLopToHop)
        SELECT DISTINCT
            l.LopID, l.MaDonVi, l.TenLop, l.KhoiID, l.GVCN,
            CAST(0 AS BIT), l.IsLopToHop
        FROM dbo.tblLop AS l
        WHERE l.NienKhoa = @NienKhoa
          AND l.Enable = 1
          AND l.KhoiID = @KhoiID
        UNION ALL
        SELECT DISTINCT
            n.NhomID, n.MaDonVi, n.TenNhom, n.KhoiID, n.GVCN,
            CAST(1 AS BIT), CAST(0 AS BIT)
        FROM dbo.tblNhom AS n
        WHERE n.NienKhoa = @NienKhoa
          AND n.Enable = 1
          AND n.KhoiID = @KhoiID
          AND n.IsNhomLMS_GiaoBai = 0;
    END
    ELSE
    BEGIN
        INSERT INTO @Table_Lop (LopID, MaDonVi, TenLop, KhoiID, GVCN, IsNhom, IsLopToHop)
        SELECT DISTINCT
            l.LopID, gvl.MaDonVi, l.TenLop, l.KhoiID, l.GVCN,
            CAST(0 AS BIT), l.IsLopToHop
        FROM dbo.tblLop AS l
        INNER JOIN dbo.tblGiaoVienLop AS gvl
            ON gvl.KhoiID = l.KhoiID
           AND gvl.LopID = l.LopID
           AND gvl.NienKhoa = l.NienKhoa
           AND gvl.GiaoVienID = @SYS_USERID
           AND gvl.HocKy = @HocKi
           AND gvl.Enable = 1
        WHERE l.NienKhoa = @NienKhoa
          AND l.Enable = 1
          AND l.KhoiID = @KhoiID
        UNION
        SELECT DISTINCT
            l.LopID, 1, l.TenLop, l.KhoiID, l.GVCN,
            CAST(0 AS BIT), l.IsLopToHop
        FROM dbo.tblLop AS l
        WHERE l.NienKhoa = @NienKhoa
          AND l.KhoiID = @KhoiID
          AND l.Enable = 1
          AND l.GVCN = @SYS_USERID
        UNION ALL
        SELECT DISTINCT
            gvl.LopID, gvl.MaDonVi, n.TenNhom, n.KhoiID, n.GVCN,
            CAST(1 AS BIT), CAST(0 AS BIT)
        FROM dbo.tblNhom AS n
        INNER JOIN dbo.tblGiaoVienLop AS gvl
            ON gvl.KhoiID = n.KhoiID
           AND gvl.LopID = n.NhomID
           AND gvl.NienKhoa = n.NienKhoa
           AND gvl.GiaoVienID = @SYS_USERID
           AND gvl.HocKy = @HocKi
           AND gvl.Enable = 1
        WHERE n.NienKhoa = @NienKhoa
          AND n.IsNhomLMS_GiaoBai = 0;
    END;

    SELECT DISTINCT LopID, MaDonVi, TenLop, KhoiID, GVCN, IsNhom, IsLopToHop
    FROM @Table_Lop
    ORDER BY TenLop;
END;
