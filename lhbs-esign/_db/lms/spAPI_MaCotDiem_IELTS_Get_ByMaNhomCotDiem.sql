-- spAPI_MaCotDiem_Get_ByMaNhomCotDiem 46, N'DiemGK_HK1'

CREATE PROC [dbo].[spAPI_MaCotDiem_IELTS_Get_ByMaNhomCotDiem]
@MaNhomCotDiem varchar(100)
AS
BEGIN
    SELECT 
		DISTINCT
		MaNhomCotDiem,
		TenNhomCotDiem_VI,
		TenCotDiem_VI,
		MaCotDiem,
		ThuTuCotDiem
	FROM dbo.TemplateBangDiemChiTiet
	WHERE MaNhomCotDiem = @MaNhomCotDiem
	AND Enable = 1
	ORDER BY ThuTuCotDiem
END