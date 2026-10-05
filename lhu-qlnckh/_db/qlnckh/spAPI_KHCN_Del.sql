CREATE PROC spAPI_KHCN_Del
@DeTaiKHCNID INT,
@Sys_UserId VARCHAR(9)
AS
BEGIN
	UPDATE [dbo].[KHCN_ThanhVien] SET Is_Xoa = 1 , NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiKHCNID = @DeTaiKHCNID 
	UPDATE [dbo].[KHCN_TienDoCapKinhPhi]  SET Is_Xoa = 1, NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiKHCNID = @DeTaiKHCNID 
	UPDATE [dbo].[KHCN_SanPham] SET Is_Xoa = 1 , NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiKHCNID = @DeTaiKHCNID 
	UPDATE [dbo].[KHCN_DeTai]  SET Is_Xoa = 1 , NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiKHCNID = @DeTaiKHCNID 
	
END 