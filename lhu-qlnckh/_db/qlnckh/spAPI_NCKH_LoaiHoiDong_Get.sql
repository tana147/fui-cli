CREATE PROC spAPI_NCKH_LoaiHoiDong_Get
AS
BEGIN
	SELECT LoaiHoiDongID, TenLoaiHoiDong
	FROM NCKH_LoaiHoiDong WHERE Is_Xoa = 0
END