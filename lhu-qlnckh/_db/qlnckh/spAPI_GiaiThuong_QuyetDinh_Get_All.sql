
CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Get_All]  --2
@LoaiQD INT
AS
BEGIN
	SELECT DISTINCT qd.QDID, 
		ISNULL(qd.MaSoQD, '') AS MaSoQD, 
		td.SoTT AS Dot, -- test
		qd.NgayQD, 
		qd.ThangQD, 
		qd.NamQD,
		qd.MoTaQD,
		(
			SELECT SUM(CASE WHEN (plt.[Data] = '' OR plt.[Data] IS NULL) THEN 0 ELSE 1 END) AS SoTapTin
			FROM dbo.FN_STRING_SPLIT(qd.FileID_List, ',') 
			AS plt
		) AS SoTapTin,
		(
			SELECT COUNT(1) AS SoGiaiThuong
			FROM dbo.GiaiThuong gt
			WHERE gt.QDID = qd.QDID
			AND gt.Is_Xoa = 0
		) AS SoGiaiThuong
		, qd.FileID_List AS  FileID
		, f.FileName 
		, '/FileData/'+ f.FileID AS FileUrl
	FROM dbo.QuyetDinh qd LEFT JOIN FileData f ON qd.FileID_List = f.FileID
	LEFT JOIN KHCN_TienDoCapKinhPhi TD ON qd.QDID = TD.QDID
	WHERE qd.Is_Xoa = 0 AND qd.LoaiQD = @LoaiQD
	--ORDER BY qd.MaSoQD
END
