CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_HuongNC_Save]
	@HuongNghienCuuChinh nvarchar(max),
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: cập nhật hướng nghiên cứu chính của chính người đăng nhập.
BEGIN
	SET NOCOUNT ON;
	SET @HuongNghienCuuChinh = NULLIF(LTRIM(RTRIM(@HuongNghienCuuChinh)), '');

	IF LEN(ISNULL(@HuongNghienCuuChinh, '')) > 4000
	BEGIN
		RAISERROR(N'Hướng nghiên cứu tối đa 4000 ký tự', 16, 1)
		RETURN
	END

	IF EXISTS (SELECT 1 FROM tblHDKH_Profile_CaNhan WHERE NhanVienID = @sys_UserID)
		UPDATE tblHDKH_Profile_CaNhan
		SET HuongNghienCuuChinh = @HuongNghienCuuChinh, IsDeleted = 0,
			UpdateTime = GETDATE(), UpdateUser = @sys_UserID
		WHERE NhanVienID = @sys_UserID
	ELSE
		INSERT INTO tblHDKH_Profile_CaNhan (NhanVienID, HoTen, HuongNghienCuuChinh, CreateTime, CreateUser, IsDeleted)
		SELECT @sys_UserID, ISNULL((SELECT TOP 1 HoTen FROM NhanVien WHERE MaNV = @sys_UserID), @sys_UserID),
			@HuongNghienCuuChinh, GETDATE(), @sys_UserID, 0

	SELECT Message = N'Đã lưu hướng nghiên cứu'
END
