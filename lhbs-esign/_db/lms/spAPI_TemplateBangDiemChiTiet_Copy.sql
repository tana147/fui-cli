CREATE PROC [dbo].[spAPI_TemplateBangDiemChiTiet_Copy]
@TemplateBangDiemID_Src INT,
@TemplateBangDiemID_Des INT,
@SYS_USERID VARCHAR(9),
@Sys_GroupID INT
AS
BEGIN
	INSERT INTO [dbo].[TemplateBangDiemChiTiet]([TemplateBangDiemID], [IDHeThong], [MaCotDiem], [TenCotDiem_VI], [TenCotDiem_EN], [TenHienThi_VI], [TenHienThi_EN], [MotaCotDiem_VI], [MotaCotDiem_EN], [LoaiCotDiem], [KieuDanhGiaID], [GiaTriCotDiem], [LamTronBaoNhieuSo], [Formula], [ThuTuCotDiem], [MaNhomCotDiem], [TenNhomCotDiem_VI], [TenNhomCotDiem_EN], [ThuTuNhom], [IsUserInput], [IsVisibleToParents], [IsSendToManager], [Enable], [CssClass], [Semester], [CreateUser], [CreateTime])
	SELECT @TemplateBangDiemID_Des, [IDHeThong], [MaCotDiem], [TenCotDiem_VI], [TenCotDiem_EN], [TenHienThi_VI], [TenHienThi_EN], [MotaCotDiem_VI], [MotaCotDiem_EN], [LoaiCotDiem], [KieuDanhGiaID], [GiaTriCotDiem], [LamTronBaoNhieuSo], [Formula], [ThuTuCotDiem], [MaNhomCotDiem], [TenNhomCotDiem_VI], [TenNhomCotDiem_EN], [ThuTuNhom], [IsUserInput], [IsVisibleToParents], [IsSendToManager], [Enable], [CssClass], Semester, @SYS_USERID, GETDATE()
	FROM [dbo].[TemplateBangDiemChiTiet] WHERE [TemplateBangDiemID] = @TemplateBangDiemID_Src
	AND [Enable] = 1
	ORDER BY ThuTuNhom, [ThuTuCotDiem]
END