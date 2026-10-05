CREATE PROC [dbo].[spAPI_GiaiThuong_Get_ByLoaiGiaiThuongID]   
	@LoaiGiaiThuongID INT
AS
BEGIN
	SELECT 
		gt.GiaiThuongID,
		gt.LoaiGiaiThuongID,
		gt.SoThuTu,
		gt.TenDeTai,
		gt.TacGia,
		gt.DonVi,
		gt.Giai,
		gt.ThangDatGiai,
		gt.NamDatGiai,
		qd.QDID,
		ISNULL(qd.MaSoQD, '') MaSoQD,
		(
			SELECT SUM(CASE WHEN (plt.[Data] = '' OR plt.[Data] IS NULL) THEN 0 ELSE 1 END) AS SoTapTin
			FROM dbo.FN_STRING_SPLIT(gt.FileID_List, ',') 
			AS plt
		) AS SoTapTin
	FROM dbo.GiaiThuong gt
		LEFT JOIN dbo.QuyetDinh qd ON qd.QDID = gt.QDID AND qd.Is_Xoa = 0
	WHERE gt.Is_Xoa = 0
		AND gt.LoaiGiaiThuongID = (CASE WHEN @LoaiGiaiThuongID = 0 THEN GT.LoaiGiaiThuongID ELSE @LoaiGiaiThuongID END)
END