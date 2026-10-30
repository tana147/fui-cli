CREATE PROCEDURE [dbo].[spAPI_ChiTieu_Dashboard_ByCapKhoi]
@CapID INT,
@KhoiID INT,
@HocKi INT,
@Is_TA2 INT
AS
BEGIN
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
	IF(@CapID = 3 AND @Is_TA2 = 0)
BEGIN
   
SELECT 
    n.TenNhom,
    n.NhomID AS LopNhomID,
    MAX(CASE WHEN md.TenMucDo = N'Không đạt' THEN ct.ChiTieuDatRa END) AS ChiTieu_KhongDat,
    MAX(CASE WHEN md.TenMucDo = N'Đạt' THEN ct.ChiTieuDatRa END) AS ChiTieu_Dat,
    MAX(CASE WHEN md.TenMucDo = N'Khá' THEN ct.ChiTieuDatRa END) AS ChiTieu_Kha,
    MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuDatRa END) AS ChiTieu_Tot,
    MAX(CASE WHEN md.TenMucDo = N'Không đạt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_KhongDat,
    MAX(CASE WHEN md.TenMucDo = N'Đạt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Dat,
    MAX(CASE WHEN md.TenMucDo = N'Khá' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Kha,
    MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Tot
FROM tbl_ChiTieu ct
INNER JOIN tblNhom n 
    ON n.NhomID = ct.NhomID 
    AND n.CapID = @CapID 
    AND n.KhoiID = @KhoiID
INNER JOIN tbl_MucDo md 
    ON md.MucDo_ID = ct.MucDo_ID
WHERE HocKi = @HocKi
GROUP BY 
    n.TenNhom,
    n.NhomID
     ORDER BY n.TenNhom
END
ELSE IF(@CapID = 2 AND @Is_TA2 = 0)
BEGIN
    SELECT 
        l.TenLop,
        l.LopID AS LopNhomID,
        MAX(CASE WHEN md.TenMucDo = N'Không đạt' THEN ct.ChiTieuDatRa END) AS ChiTieu_KhongDat,
        MAX(CASE WHEN md.TenMucDo = N'Đạt' THEN ct.ChiTieuDatRa END) AS ChiTieu_Dat,
        MAX(CASE WHEN md.TenMucDo = N'Khá' THEN ct.ChiTieuDatRa END) AS ChiTieu_Kha,
        MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuDatRa END) AS ChiTieu_Tot,
        MAX(CASE WHEN md.TenMucDo = N'Không đạt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_KhongDat,
        MAX(CASE WHEN md.TenMucDo = N'Đạt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Dat,
        MAX(CASE WHEN md.TenMucDo = N'Khá' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Kha,
        MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Tot
    FROM tbl_ChiTieu ct
    INNER JOIN tblLop l 
        ON l.LopID = ct.LopID 
        AND l.NienKhoa = @NienKhoa
        AND l.CapID = @CapID 
        AND l.KhoiID = @KhoiID
    INNER JOIN tbl_MucDo md 
        ON md.MucDo_ID = ct.MucDo_ID
    WHERE HocKi = @HocKi
    GROUP BY 
        l.TenLop,
        l.LopID
        ORDER BY 
        l.TenLop
        END
ELSE IF(@CapID = 1 AND @Is_TA2 = 0)
    BEGIN
        SELECT 
        l.TenLop,
        l.LopID AS LopNhomID,
        MAX(CASE WHEN md.TenMucDo = N'Hoàn thành' THEN ct.ChiTieuDatRa END) AS ChiTieu_HoanThanh,
        MAX(CASE WHEN md.TenMucDo = N'Chưa hoàn thành' THEN ct.ChiTieuDatRa END) AS ChiTieu_ChuaHoanThanh,
        MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuDatRa END) AS ChiTieu_Tot,
        MAX(CASE WHEN md.TenMucDo = N'Hoàn thành' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_HoanThanh,
        MAX(CASE WHEN md.TenMucDo = N'Chưa hoàn thành' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_ChuaHoanThanh,
        MAX(CASE WHEN md.TenMucDo = N'Tốt' THEN ct.ChiTieuThucTe END) AS ChiTieuThucTe_Tot
    FROM tbl_ChiTieu ct
    INNER JOIN tblLop l 
        ON l.LopID = ct.LopID 
        AND l.NienKhoa = @NienKhoa
        AND l.CapID = @CapID 
        AND l.KhoiID = @KhoiID
    INNER JOIN tbl_MucDo md 
        ON md.MucDo_ID = ct.MucDo_ID
    WHERE HocKi = @HocKi
    GROUP BY 
        l.TenLop,
        l.LopID
    ORDER BY 
        l.TenLop
    END
ELSE IF(@CapID = 3 AND @Is_TA2 = 1)
BEGIN
   SELECT 
        n.TenNhom,
        n.NhomID AS LopNhomID,
        ct.TrinhDo,
        ct.ChiTieuDatRa,
        ct.ChiTieuThucTe
    FROM tbl_ChiTieu ct
    INNER JOIN tblNhom n 
        ON n.NhomID = ct.NhomID 
        AND n.CapID = @CapID 
        AND n.KhoiID = @KhoiID
    INNER JOIN tbl_MucDo md 
        ON md.MucDo_ID = ct.MucDo_ID and md.Is_TA2 = 1
    WHERE HocKi = 1
    GROUP BY 
        n.TenNhom,
        n.NhomID,
        ct.TrinhDo,
        ct.ChiTieuDatRa,
        ct.ChiTieuThucTe
         ORDER BY n.TenNhom
END


SELECT MucDo_ID,TenMucDo,CapID FROM tbl_MucDo WHERE CapID = @CapID AND (@Is_TA2 = 0 AND MucDo_ID not in (14,15) OR @Is_TA2 = 1 AND MucDo_ID in (14,15)) AND Enable = 1  ORDER BY Sort

SELECT @Is_TA2
END