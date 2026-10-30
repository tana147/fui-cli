
CREATE PROCEDURE [dbo].[spAPI_BaoCaoChiTieu_GetLop]
    @NienKhoa int
AS
BEGIN
    SELECT 
        l.TenLop,
        l.CapID,
        l.KhoiID,
        l.LopID,
        COUNT(hsl.HocSinhID) AS SiSo,
        CAST(1 as bit) AS Is_TA1
    FROM 
        dbo.tblLop AS l
        INNER JOIN dbo.tblHocSinhLop AS hsl 
            ON hsl.LopID = l.LopID 
            AND hsl.Enable = 1
    WHERE 
        l.NienKhoa = @NienKhoa
    GROUP BY 
        l.TenLop,
        l.CapID,
        l.KhoiID,
        l.LopID
    
    UNION ALL
    
    SELECT 
        n.TenNhom,
        n.CapID,
        n.KhoiID,
        n.NhomID,
        COUNT(hsn.HocSinhID) AS SiSo,
        CAST(0 as bit) AS Is_TA1
    FROM 
        dbo.tblNhom AS n
        INNER JOIN dbo.tblHocSinhNhom AS hsn 
            ON hsn.NhomID = n.NhomID 
            AND hsn.Enable = 1
    WHERE 
        n.NienKhoa = @NienKhoa
        AND n.MonHocID IN (5, 46, 76)
        AND n.IsNhomLMS_GiaoBai <> 1
    GROUP BY 
        n.TenNhom,
        n.CapID,
        n.KhoiID,
        n.NhomID
    ORDER BY 
        KhoiID;

END
