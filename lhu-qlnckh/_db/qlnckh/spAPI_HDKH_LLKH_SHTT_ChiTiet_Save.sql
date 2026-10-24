CREATE PROCEDURE [dbo].[spAPI_HDKH_LLKH_SHTT_ChiTiet_Save]
	@Nguon varchar(20),
	@ID bigint,
	@SoVanBang nvarchar(100),
	@NamCap varchar(20),
	@NoiCapVanBang nvarchar(255),
	@sys_UserID varchar(9)
AS
-- Lý lịch khoa học: bổ sung / cập nhật số văn bằng, năm cấp, nơi cấp cho SHTT đồng bộ vào Single Source of Truth
BEGIN
	SET NOCOUNT ON;

	SET @SoVanBang = NULLIF(LTRIM(RTRIM(@SoVanBang)), '');
	SET @NamCap = NULLIF(LTRIM(RTRIM(@NamCap)), '');
	SET @NoiCapVanBang = NULLIF(LTRIM(RTRIM(@NoiCapVanBang)), '');

	IF @Nguon = 'KHEN_THUONG'
	BEGIN
		-- 1. Kiểm tra quyền tác giả trên khen thưởng SHTT
		IF NOT EXISTS (
			SELECT 1 FROM ThiKHCN_ThanhVien
			WHERE KhenThuongID = @ID AND MaDinhDanh = @sys_UserID AND Is_Xoa = 0
		)
		BEGIN
			RAISERROR(N'Bạn không có quyền chỉnh sửa mục khen thưởng SHTT này', 16, 1);
			RETURN;
		END

		UPDATE ThiKHCN_KhenThuong
		SET SoQuyetDinh_VanBang = ISNULL(@SoVanBang, SoQuyetDinh_VanBang),
			NgayBanHanh = CASE
				WHEN ISDATE(@NamCap) = 1 THEN CAST(@NamCap AS date)
				WHEN @NamCap LIKE '[12][0-9][0-9][0-9]' THEN CAST(@NamCap + '-01-01' AS date)
				ELSE NgayBanHanh END,
			NoiCapVanBang = @NoiCapVanBang
		WHERE KhenThuongID = @ID;

		SELECT Message = N'Cập nhật thông tin SHTT thành công', Status = 1;
		RETURN;
	END

	IF @Nguon = 'KE_KHAI'
	BEGIN
		-- 2. Kiểm tra quyền trên bản kê khai giờ SHTT
		IF NOT EXISTS (
			SELECT 1 FROM tblHDKH_KeKhai_Submission SB
			WHERE SB.SubmissionID = @ID AND SB.IsDeleted = 0
				AND (SB.NhanVienID_KeKhai = @sys_UserID OR EXISTS (
					SELECT 1 FROM tblHDKH_KeKhai_ThanhVien TV
					WHERE TV.SubmissionID = SB.SubmissionID AND TV.NhanVienID = @sys_UserID AND TV.IsDeleted = 0
				))
		)
		BEGIN
			RAISERROR(N'Bạn không có quyền chỉnh sửa mục kê khai SHTT này', 16, 1);
			RETURN;
		END

		DECLARE @Field_SoVanBang int, @Field_NamCap int, @Field_NoiCap int;
		SELECT @Field_SoVanBang = FieldID FROM tblHDKH_Field_Definition WHERE FormID = 14 AND FieldName = 'so_van_bang' AND IsDeleted = 0;
		SELECT @Field_NamCap = FieldID FROM tblHDKH_Field_Definition WHERE FormID = 14 AND FieldName = 'nam_cap' AND IsDeleted = 0;
		SELECT @Field_NoiCap = FieldID FROM tblHDKH_Field_Definition WHERE FormID = 14 AND FieldName = 'noi_cap_van_bang' AND IsDeleted = 0;

		-- Số văn bằng
		IF EXISTS (SELECT 1 FROM tblHDKH_KeKhai_FieldValue WHERE SubmissionID = @ID AND FieldID = @Field_SoVanBang)
			UPDATE tblHDKH_KeKhai_FieldValue
			SET FieldValue = @SoVanBang, UpdateTime = GETDATE(), UpdateUser = @sys_UserID, IsDeleted = 0
			WHERE SubmissionID = @ID AND FieldID = @Field_SoVanBang;
		ELSE IF @SoVanBang IS NOT NULL
			INSERT INTO tblHDKH_KeKhai_FieldValue (SubmissionID, FieldID, FieldValue, CreateTime, CreateUser, IsDeleted)
			VALUES (@ID, @Field_SoVanBang, @SoVanBang, GETDATE(), @sys_UserID, 0);

		-- Năm cấp
		IF EXISTS (SELECT 1 FROM tblHDKH_KeKhai_FieldValue WHERE SubmissionID = @ID AND FieldID = @Field_NamCap)
			UPDATE tblHDKH_KeKhai_FieldValue
			SET FieldValue = @NamCap, UpdateTime = GETDATE(), UpdateUser = @sys_UserID, IsDeleted = 0
			WHERE SubmissionID = @ID AND FieldID = @Field_NamCap;
		ELSE IF @NamCap IS NOT NULL
			INSERT INTO tblHDKH_KeKhai_FieldValue (SubmissionID, FieldID, FieldValue, CreateTime, CreateUser, IsDeleted)
			VALUES (@ID, @Field_NamCap, @NamCap, GETDATE(), @sys_UserID, 0);

		-- Nơi cấp văn bằng
		IF EXISTS (SELECT 1 FROM tblHDKH_KeKhai_FieldValue WHERE SubmissionID = @ID AND FieldID = @Field_NoiCap)
			UPDATE tblHDKH_KeKhai_FieldValue
			SET FieldValue = @NoiCapVanBang, UpdateTime = GETDATE(), UpdateUser = @sys_UserID, IsDeleted = 0
			WHERE SubmissionID = @ID AND FieldID = @Field_NoiCap;
		ELSE IF @NoiCapVanBang IS NOT NULL
			INSERT INTO tblHDKH_KeKhai_FieldValue (SubmissionID, FieldID, FieldValue, CreateTime, CreateUser, IsDeleted)
			VALUES (@ID, @Field_NoiCap, @NoiCapVanBang, GETDATE(), @sys_UserID, 0);

		SELECT Message = N'Cập nhật thông tin SHTT thành công', Status = 1;
		RETURN;
	END

	RAISERROR(N'Nguồn dữ liệu không hợp lệ', 16, 1);
END;
