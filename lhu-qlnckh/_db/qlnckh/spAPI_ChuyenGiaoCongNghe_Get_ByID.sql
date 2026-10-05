CREATE PROC [dbo].[spAPI_ChuyenGiaoCongNghe_Get_ByID]  -- 0
	@CGCNID INT
AS
BEGIN

	-- Thông tin chuyển giao công nghệ
	SELECT 
		  cn.[CGCNID]
		, cn.[SoThuTu]
		, cn.[TenDuAn]
		, cn.[ChuNhiemDeTai]
		, cn.[ThanhVienDeTai]
		, cn.[DonViChuNhiem]
		, cn.[DonViTiepNhan]
		, cn.[GiaTriHopDong]
		, cn.[NamThucHien]
		, cn.[SoHopDong]
		, cn.[FileID_List]
		, cn.[NhanVienCapNhat]
		, cn.[ThoiGianCapNhat]
		, cn.[Is_Xoa]

	FROM dbo.ChuyenGiaoCongNghe cn
	WHERE cn.Is_Xoa = 0
		AND cn.CGCNID = @CGCNID

	-- Danh sách tập tin đính kèm
	SELECT fd.FileID AS [FILE_ID], fd.[FileName] AS [FILE_NAME], fd.Size AS FILE_SIZE
	FROM dbo.FileData fd
		INNER JOIN dbo.ChuyenGiaoCongNghe cn ON CHARINDEX(fd.FileID, cn.FileID_List) > 0
	WHERE cn.Is_Xoa = 0
		AND (cn.CGCNID = @CGCNID )
		
END