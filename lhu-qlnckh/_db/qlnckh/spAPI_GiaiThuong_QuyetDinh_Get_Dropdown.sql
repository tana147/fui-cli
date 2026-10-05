CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Get_Dropdown]
@LoaiQD INT
AS
BEGIN
	SELECT qd.QDID, 
		(ISNULL(qd.MaSoQD, '') + ' - ' + qd.MoTaQD) AS MaSoQD
	FROM dbo.QuyetDinh qd
	WHERE qd.Is_Xoa = 0
		AND (qd.MaSoQD IS NOT NULL AND qd.MaSoQD <> '') AND qd.LoaiQD = @LoaiQD
	ORDER BY qd.MaSoQD
END

