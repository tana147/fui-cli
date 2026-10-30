
CREATE PROC	[dbo].[spAPI_NhomCauTrucDiem_Get_All_ByTemplateBangDiemID]
@TemplateBangDiemID INT
AS
BEGIN
    SELECT DISTINCT
		[MaNhomCotDiem],
		[TenNhomCotDiem_VI],
		[TenNhomCotDiem_EN],
		[ThuTuNhom],
		[Semester],
		MaCotDiem,
		ThuTuCotDiem,
		GiaTriCotDiem,
		LoaiCotDiem,
		Formula,
		DiemMin,
		DiemMax,
		CotDiemID,
		QuyenNhapDiem,
		TenCotDiem_VI,
		TenCotDiem_EN,
		HexBackground
	FROM [dbo].[TemplateBangDiemChiTiet] 
	WHERE [TemplateBangDiemID] = @TemplateBangDiemID
		AND [Enable] = 1
	ORDER BY Semester,
			ThuTuNhom,
			ThuTuCotDiem;
END 