CREATE PROC [dbo].[spAPI_GiaiThuong_Del]
	@Sys_UserId VARCHAR(9),
	@GiaiThuongID INT
AS
BEGIN
	UPDATE dbo.GiaiThuong
	SET
		Is_Xoa					= 1,
	    NhanVienCapNhat			= @Sys_UserId,	
		ThoiGianCapNhat			= GETDATE()
	WHERE GiaiThuongID = @GiaiThuongID
END