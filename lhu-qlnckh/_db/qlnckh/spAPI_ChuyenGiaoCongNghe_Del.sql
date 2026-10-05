CREATE PROC [dbo].[spAPI_ChuyenGiaoCongNghe_Del]
	@Sys_UserId VARCHAR(9),
	@CGCNID INT
AS
BEGIN
	UPDATE dbo.ChuyenGiaoCongNghe
	SET
		Is_Xoa					= 1,
	    NhanVienCapNhat			= @Sys_UserId,	
		ThoiGianCapNhat			= GETDATE()
	WHERE CGCNID = @CGCNID
END