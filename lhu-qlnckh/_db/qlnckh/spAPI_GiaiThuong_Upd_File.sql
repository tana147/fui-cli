CREATE PROC [dbo].[spAPI_GiaiThuong_Upd_File]   
	@Sys_UserId VARCHAR(9),
	@GiaiThuongID INT,
	@DS_FileID NVARCHAR(2000)
AS
BEGIN

	-- Cập nhật số quyết định
	UPDATE dbo.GiaiThuong
	SET FileID_List = @DS_FileID,
		NhanVienCapNhat = @Sys_UserId,
		ThoiGianCapNhat = GETDATE()
	WHERE GiaiThuongID = @GiaiThuongID
END

