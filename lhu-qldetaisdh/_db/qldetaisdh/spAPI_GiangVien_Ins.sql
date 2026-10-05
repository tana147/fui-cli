
CREATE PROC [dbo].[spAPI_GiangVien_Ins]
@HocViHocHam NVARCHAR(10),
@HoTenGiangVien NVARCHAR(500),
@CoQuanCongTac NVARCHAR(500),
@CoQuanCongTacTiengViet NVARCHAR(500),
@NganhID INT,
@NganhGiangDay NVARCHAR(200),
@DiaChi NVARCHAR(500),
@SoDienThoai VARCHAR(10),

@SoTKNganHang NVARCHAR(255),
@TenNganHang NVARCHAR(255),
@MaSoThue NVARCHAR(100),
@Email_GV NVARCHAR(100),
@FileVanBang_ID NVARCHAR(50),
@FileVanBang_Name NVARCHAR(255),
@FileVanBang_Url NVARCHAR(500),
@FileLyLichKH_ID NVARCHAR(50),
@FileLyLichKH_Name NVARCHAR(255),
@FileLyLichKH_Url NVARCHAR(500),

@SYS_UserID VARCHAR(9),
@Sys_GroupID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	ELSE
	BEGIN
		INSERT INTO dbo.GiangVien
		( 
			HocViHocHam, 
			HoTenGiangVien, 
			CoQuanCongTac, 
			CoQuanCongTacTiengViet,
			NganhGiangDay, 
			NganhID, 
			DiaChi, 
			SoDienThoai, 
			SoTKNganHang, 
			TenNganHang, 
			MaSoThue, 
			Email_GV, 
			FileVanBang_ID, 
			FileVanBang_Name, 
			FileVanBang_Url, 
			FileLyLichKH_ID, 
			FileLyLichKH_Name, 
			FileLyLichKH_Url,
			Created_By, 
			Created_At
		)
		VALUES
		( 
			@HocViHocHam, 
			@HoTenGiangVien, 
			@CoQuanCongTac, 
			@CoQuanCongTacTiengViet,
			@NganhGiangDay, 
			@NganhID, 
			@DiaChi, 
			@SoDienThoai,
			@SoTKNganHang,
			@TenNganHang,
			@MaSoThue,
			@Email_GV,
			@FileVanBang_ID,
			@FileVanBang_Name,
			@FileVanBang_Url,
			@FileLyLichKH_ID,
			@FileLyLichKH_Name,
			@FileLyLichKH_Url,
			@SYS_UserID, 
			GETDATE()
		)
	END
END