CREATE PROC [dbo].[spAPI_GiaiThuong_Get_ByID]   
	@GiaiThuongID INT
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
		AND gt.GiaiThuongID = @GiaiThuongID

	-- Danh sách tập tin đính kèm
	SELECT fd.FileID AS [FILE_ID], fd.[FileName] AS [FILE_NAME], fd.Size AS FILE_SIZE
	FROM dbo.FileData fd
		INNER JOIN dbo.GiaiThuong gt ON CHARINDEX(fd.FileID, gt.FileID_List) > 0
	WHERE gt.Is_Xoa = 0
		AND gt.GiaiThuongID = @GiaiThuongID
		
END