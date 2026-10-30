
CREATE PROC [dbo].[spAPI_CotDiem_Get_ByTemplateBangDiemID_MaNhom]
@TemplateBangDiemID INT,
@MaNhomCotDiem NVARCHAR(100),
@SYS_USERID VARCHAR(9),
@Sys_GroupID INT

AS
BEGIN
	SELECT [CotDiemID]
	, [TemplateBangDiemID]
	, [IDHeThong]
	, [MaCotDiem]
	, [TenCotDiem_VI]
	, [TenCotDiem_EN]
	, [TenHienThi_VI]
	, [TenHienThi_EN]
	, [MotaCotDiem_VI]
	, [MotaCotDiem_EN]
	, [LoaiCotDiem]
	, [KieuDanhGiaID]
	, [GiaTriCotDiem]
	, [LamTronBaoNhieuSo]
	, [Formula]
	, [ThuTuCotDiem]
	, [MaNhomCotDiem]
	, [TenNhomCotDiem_VI]
	, [TenNhomCotDiem_EN]
	, [ThuTuNhom]
	, [IsUserInput]
	, [IsVisibleToParents]
	, [IsSendToManager]
	, [Enable]
	, [CssClass]
	, HexBackground
	, [Semester]

	FROM [dbo].[TemplateBangDiemChiTiet] WHERE [TemplateBangDiemID] = @TemplateBangDiemID AND MaNhomCotDiem = @MaNhomCotDiem
	AND [Enable] = 1
	ORDER BY ThuTuNhom, [ThuTuCotDiem]
END