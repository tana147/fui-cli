CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_DeTaiNgoai_Save]
	@DeTaiID bigint,
	@TenDeTai nvarchar(1000),
	@CoQuanTaiTro nvarchar(255),
	@ThoiGianThucHien nvarchar(100),
	@VaiTro nvarchar(100),
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: Giảng viên tự khai đề tài cấp Bộ / ngoài trường
BEGIN
	SET NOCOUNT ON;

	SET @TenDeTai = NULLIF(LTRIM(RTRIM(@TenDeTai)), '');
	IF @TenDeTai IS NULL
	BEGIN
		RAISERROR(N'Tên đề tài không được để trống', 16, 1);
		RETURN;
	END

	IF @DeTaiID IS NOT NULL AND @DeTaiID > 0
	BEGIN
		UPDATE tblHDKH_Profile_DeTaiDaThamGia
		SET TenDeTai = @TenDeTai,
			CoQuanTaiTro = @CoQuanTaiTro,
			ThoiGianThucHien = @ThoiGianThucHien,
			VaiTro = @VaiTro,
			UpdateTime = GETDATE(),
			UpdateUser = @sys_UserID
		WHERE DeTaiID = @DeTaiID AND NhanVienID = @sys_UserID;
	END
	ELSE
	BEGIN
		INSERT INTO tblHDKH_Profile_DeTaiDaThamGia (
			NhanVienID, TenDeTai, CoQuanTaiTro, ThoiGianThucHien, VaiTro,
			CreateTime, CreateUser, IsDeleted
		) VALUES (
			@sys_UserID, @TenDeTai, @CoQuanTaiTro, @ThoiGianThucHien, @VaiTro,
			GETDATE(), @sys_UserID, 0
		);
	END

	SELECT Status = 1, Message = N'Lưu đề tài thành công';
END;
