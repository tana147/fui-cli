
CREATE PROC spAPI_NCKH_Del
@DeTaiNCKHID INT,
@Sys_UserId VARCHAR(9)
AS
BEGIN
		UPDATE [dbo].[NCKH_ThanhVien] SET Is_Xoa = 1 , NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiNCKHID = @DeTaiNCKHID 
		UPDATE [dbo].[NCKH_DeTai]  SET Is_Xoa = 1 , NhanVienCapNhat = @Sys_UserId, ThoiGianCapNhat = GETDATE() WHERE DeTaiNCKHID = @DeTaiNCKHID
END
