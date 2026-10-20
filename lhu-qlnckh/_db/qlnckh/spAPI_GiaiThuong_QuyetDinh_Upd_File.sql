CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Upload_File]   
	@Sys_UserId VARCHAR(9),
	@QDID INT,
	@DS_FileID NVARCHAR(2000)
AS
BEGIN

	-- Cập nhật tập tin
	UPDATE dbo.QuyetDinh
	SET FileID_List = @DS_FileID,
		NhanVienCapNhat = @Sys_UserId,
		ThoiGianCapNhat = GETDATE()
	WHERE QDID = @QDID
END

