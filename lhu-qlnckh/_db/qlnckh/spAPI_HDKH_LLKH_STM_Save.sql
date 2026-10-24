CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_STM_Save]
	@TomTatKinhNghiem nvarchar(1000),
	@ORCID varchar(100),
	@GoogleScholar nvarchar(500),
	@ResearchGate nvarchar(500),
	@MaSTI varchar(100),
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: cập nhật thông tin khoa học (theo STM) của chính người đăng nhập.
BEGIN
	SET NOCOUNT ON;

	SET @TomTatKinhNghiem = NULLIF(LTRIM(RTRIM(@TomTatKinhNghiem)), '');
	SET @ORCID = NULLIF(LTRIM(RTRIM(@ORCID)), '');
	SET @GoogleScholar = NULLIF(LTRIM(RTRIM(@GoogleScholar)), '');
	SET @ResearchGate = NULLIF(LTRIM(RTRIM(@ResearchGate)), '');
	SET @MaSTI = NULLIF(LTRIM(RTRIM(@MaSTI)), '');

	IF EXISTS (SELECT 1 FROM tblHDKH_Profile_CaNhan WHERE NhanVienID = @sys_UserID)
		UPDATE tblHDKH_Profile_CaNhan
		SET TomTatKinhNghiem = @TomTatKinhNghiem,
			ORCID = @ORCID,
			GoogleScholar = @GoogleScholar,
			ResearchGate = @ResearchGate,
			MaSTI = @MaSTI,
			IsDeleted = 0,
			UpdateTime = GETDATE(),
			UpdateUser = @sys_UserID
		WHERE NhanVienID = @sys_UserID
	ELSE
		INSERT INTO tblHDKH_Profile_CaNhan (
			NhanVienID, HoTen, TomTatKinhNghiem, ORCID, GoogleScholar, ResearchGate, MaSTI,
			CreateTime, CreateUser, IsDeleted
		)
		SELECT @sys_UserID,
			ISNULL((SELECT TOP 1 HoTen FROM NhanVien WHERE MaNV = @sys_UserID), @sys_UserID),
			@TomTatKinhNghiem, @ORCID, @GoogleScholar, @ResearchGate, @MaSTI,
			GETDATE(), @sys_UserID, 0;

	SELECT Message = N'Đã lưu thông tin khoa học (STM)';
END
