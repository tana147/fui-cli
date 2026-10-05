CREATE PROC [dbo].[___spAPI_GiaiThuong_Get_Search]
	@TuKhoa NVARCHAR(500)
AS
BEGIN
	SELECT TOP (30)
		gt.GiaiThuongID,
		gt.TenDeTai
	FROM dbo.GiaiThuong gt
	WHERE gt.Is_Xoa = 0
		AND (
			@TuKhoa = '' 
			OR @TuKhoa IS NULL 
			OR ISNULL(gt.TenDeTai, '') + ISNULL(gt.TacGia, '') COLLATE SQL_Latin1_General_CP1_CI_AI LIKE N'%' + @TuKhoa + '%'
		)
	ORDER BY gt.TenDeTai
END