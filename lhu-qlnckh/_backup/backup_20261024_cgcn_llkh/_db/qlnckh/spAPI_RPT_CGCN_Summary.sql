CREATE PROC [dbo].[spAPI_RPT_CGCN_Summary]
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	SELECT NamHoc AS NamThucHien, COUNT(*) AS SL_HD, SUM(GiaTriHopDong) AS GT_HD
	FROM dbo.ChuyenGiaoCongNghe
	WHERE Is_Xoa = 0
	GROUP BY NamHoc
	ORDER BY NamHoc;

	SELECT DonViTiepNhan, COUNT(*) AS SL_HD, SUM(GiaTriHopDong) AS GT_HD
	FROM dbo.ChuyenGiaoCongNghe
	WHERE Is_Xoa = 0
	GROUP BY DonViTiepNhan
	ORDER BY DonViTiepNhan;
END
