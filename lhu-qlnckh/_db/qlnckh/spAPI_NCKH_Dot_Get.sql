CREATE PROC [dbo].[spAPI_NCKH_Dot_Get]
AS
BEGIN
	SELECT DotId, TenDot, D.NamHoc, D.LoaiHoiDong, L.TenLoaiHoiDong
	FROM NCKH_Dot D INNER JOIN NCKH_LoaiHoiDong L ON D.LoaiHoiDong = L.LoaiHoiDongID
	WHERE D.Is_Xoa = 0 AND L.Is_Xoa = 0
	ORDER BY 1 DESC
END