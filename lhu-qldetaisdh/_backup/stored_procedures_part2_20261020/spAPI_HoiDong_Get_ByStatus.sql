CREATE PROC [dbo].[spAPI_HoiDong_Get_ByStatus] 
AS
BEGIN
	SELECT
		[HoiDongID], [StudentID], [DeTai], [Decision_ID], [LoaiHoiDong], ThoiGianBaoVe
	FROM 
		[dbo].[HoiDong] WHERE [HoiDong_Status] = 0
END
