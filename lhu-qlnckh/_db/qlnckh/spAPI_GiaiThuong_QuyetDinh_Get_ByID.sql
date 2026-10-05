CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Get_ByID]   
	@QDID INT
AS
BEGIN

	-- Lấy thông tin quyết định
	SELECT qd.QDID, qd.MaSoQD, qd.MoTaQD, qd.NgayQD, qd.ThangQD, qd.NamQD
	FROM dbo.QuyetDinh qd
	WHERE qd.QDID = @QDID

	-- Danh sách tập tin đính kèm
	SELECT fd.FileID AS [FILE_ID], fd.[FileName] AS [FILE_NAME], fd.Size AS FILE_SIZE
	FROM dbo.FileData fd
		INNER JOIN dbo.QuyetDinh qd ON CHARINDEX(fd.FileID, qd.FileID_List) > 0
	WHERE qd.QDID = @QDID
		
END