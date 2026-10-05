CREATE PROC [dbo].[spAPI_TaiKhoan_Get]
@MaNV VARCHAR(9)
AS
BEGIN
	SELECT [MaNV], [HoNV], [TenNV], [TenThe], [BankIDVietQR], [BankCodeVietQR], [BankNameVietQR], [TaiKhoan]
	FROM [dbo].[TaiKhoan] TK WHERE MaNV = @MaNV AND Is_Xoa = 0
END