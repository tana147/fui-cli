CREATE PROC [dbo].[spAPI_KHCN_ThanhVien_Get_ByID]
@DeTaiKHCNID INT
AS
BEGIN
	SELECT  [ThanhVienKHCNID]
	, [DeTaiKHCNID]
	, [STT]
	, [Is_ChuNhiem]
	, [Is_NhanVien]
	, [Is_SinhVien]
	, [MaNhanVien]
	, [Ho]
	, [Ten]
	, [Email]
	, [TenPhongBan]
	, [SoTaiKhoan]
	, [NganHang]
	, [TenChuTaiKhoan]
	FROM [dbo].[KHCN_ThanhVien] 
	WHERE DeTaiKHCNID = @DeTaiKHCNID AND Is_Xoa = 0
END