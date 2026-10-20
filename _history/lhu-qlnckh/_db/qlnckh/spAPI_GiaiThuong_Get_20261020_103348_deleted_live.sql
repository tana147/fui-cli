CREATE PROC [dbo].[spAPI_GiaiThuong_Get]   
AS
BEGIN
	-- Thông tin giải thưởng
	SELECT 
		gt.GiaiThuongID,
		gt.LoaiGiaiThuongID,
		gt.SoThuTu,
		gt.TenDeTai,
		gt.TacGia,
		gt.DonVi,
		gt.Giai,
		gt.NamDatGiai,
		ISNULL(qd.MaSoQD, '') AS MaSoQD,
		qd.QDID
	FROM dbo.GiaiThuong gt
		LEFT JOIN dbo.QuyetDinh qd ON qd.QDID = gt.QDID AND qd.Is_Xoa = 0
	WHERE gt.Is_Xoa = 0
		
END