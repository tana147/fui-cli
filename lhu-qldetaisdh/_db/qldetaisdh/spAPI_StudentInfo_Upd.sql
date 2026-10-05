CREATE PROC [dbo].[spAPI_StudentInfo_Upd]
	@StudentID VARCHAR(9),
	@NoiSinh NVARCHAR(200),
	@Email VARCHAR(100),
	@SoDienThoai VARCHAR(15),
	@GioiTinh NVARCHAR(5),
	@DanToc NVARCHAR(50),
	@QuocTich NVARCHAR(150),
	@CCCD VARCHAR(12),
	@NgayCap_CCCD VARCHAR(20),
	@Truong_DaiHoc NVARCHAR(400),
	@Nganh_DaiHoc NVARCHAR(150),
	@ThoiGianTotNghiep_DaiHoc VARCHAR(50),
	@Truong_ThacSi NVARCHAR(400),
	@Nganh_ThacSi NVARCHAR(150),
	@ThoiGianTotNghiep_ThacSi VARCHAR(50),
	@XepLoai NVARCHAR(120),
	@NgoaiNgu_DauVao NVARCHAR(300),
	@Loai_NgoaiNgu_DauVao NVARCHAR(50),
	@BoSungKienThuc NVARCHAR(50),
	@CongBoKhoaHoc NVARCHAR(50),
	@DiaChi NVARCHAR(500),
	@NoiLamViec NVARCHAR(500),
	@NgheNghiep NVARCHAR(200),
	@HeDaoTao_DaiHoc NVARCHAR(100),
	@HeDaoTao_ThacSi NVARCHAR(100),
	@SYS_UserID VARCHAR(9),
	@sys_SystemRight INT,
	@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)

	DECLARE @IsTienSi BIT = 0
	IF EXISTS (
		SELECT 1 FROM StudentInfo 
		WHERE StudentID = @StudentID 
		  AND (HeDaoTao = 'Phd' OR SUBSTRING(LopID, 3, 1) = 'N' OR NganhID IN ('43', '44'))
	)
	BEGIN
		SET @IsTienSi = 1
	END

	IF @IsTienSi = 1
	BEGIN
		-- Tiến sĩ: FunctionRight = 2 (hoặc SystemRight = 9 admin)
		IF (@sys_SystemRight <> 9 AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE
	BEGIN
		-- Thạc sĩ: giữ như cũ
		IF (@sys_SystemRight NOT IN (2,3,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	
	-- Insert vào bảng UPDATE để backup
	INSERT INTO StudentInfo_UPDATE (
		StudentID,
		HoSV,
		TenSV,
		LopID,
		KhoaID,
		NganhID,
		TenNganh,
		HeDaoTaoID,
		HeDaoTao,
		NienKhoa,
		NgaySinh,
		NoiSinh,
		GioiTinh,
		SoDienThoai,
		Email,
		DanToc,
		QuocTich,
		CCCD,
		NgayCap_CCCD,
		Truong_DaiHoc,
		Nganh_DaiHoc,
		ThoiGianTotNghiep_DaiHoc,
		Truong_ThacSi,
		Nganh_ThacSi,
		ThoiGianTotNghiep_ThacSi,
		XepLoai,
		NgoaiNgu_DauVao,
		BoSungKienThuc,
		CongBoKhoaHoc,
		Loai_NgoaiNgu_DauVao,
		IsXuLyHocVu,
		IsHoanThanhThacSi,
		DiaChi,
		NoiLamViec,
		NgheNghiep,
		HeDaoTao_DaiHoc,
		HeDaoTao_ThacSi,
		Use_YN,
		CreateUser,
		CreateTime
	)
	SELECT 
		si.StudentID,
		si.HoSV,
		si.TenSV,
		si.LopID,
		si.KhoaID,
		si.NganhID,
		si.TenNganh,
		si.HeDaoTaoID,
		si.HeDaoTao,
		si.NienKhoa,
		si.NgaySinh,
		si.NoiSinh,
		si.GioiTinh,
		si.SoDienThoai,
		si.Email,
		si.DanToc,
		si.QuocTich,
		si.CCCD,
		si.NgayCap_CCCD,
		si.Truong_DaiHoc,
		si.Nganh_DaiHoc,
		si.ThoiGianTotNghiep_DaiHoc,
		si.Truong_ThacSi,
		si.Nganh_ThacSi,
		si.ThoiGianTotNghiep_ThacSi,
		si.XepLoai,
		si.NgoaiNgu_DauVao,
		si.BoSungKienThuc,
		si.CongBoKhoaHoc,
		si.Loai_NgoaiNgu_DauVao,
		si.IsXuLyHocVu,
		si.IsHoanThanhThacSi,
		si.DiaChi,
		si.NoiLamViec,
		si.NgheNghiep,
		si.HeDaoTao_DaiHoc,
		si.HeDaoTao_ThacSi,
		0,
		@SYS_UserID,
		GETDATE()
	FROM StudentInfo si
	WHERE si.StudentID = @StudentID

	UPDATE StudentInfo
	SET NoiSinh = @NoiSinh,
		Email = @Email,
		SoDienThoai = @SoDienThoai,
		DanToc = @DanToc,
		QuocTich = @QuocTich,
		CCCD = @CCCD,
		NgayCap_CCCD = COALESCE(TRY_CONVERT(DATE, NULLIF(@NgayCap_CCCD, ''), 105), TRY_CONVERT(DATE, NULLIF(@NgayCap_CCCD, ''), 103), TRY_CAST(NULLIF(@NgayCap_CCCD, '') AS DATE)),
		ThoiGianTotNghiep_DaiHoc = @ThoiGianTotNghiep_DaiHoc,
		Truong_DaiHoc = @Truong_DaiHoc,
		Nganh_DaiHoc = @Nganh_DaiHoc,
		ThoiGianTotNghiep_ThacSi = @ThoiGianTotNghiep_ThacSi,
		Truong_ThacSi = @Truong_ThacSi,
		Nganh_ThacSi = @Nganh_ThacSi,
		XepLoai = @XepLoai,
		NgoaiNgu_DauVao = @NgoaiNgu_DauVao,
		Loai_NgoaiNgu_DauVao = @Loai_NgoaiNgu_DauVao,
		BoSungKienThuc = @BoSungKienThuc,
		CongBoKhoaHoc = @CongBoKhoaHoc,
		GioiTinh = @GioiTinh,
		DiaChi = @DiaChi,
		NoiLamViec = @NoiLamViec,
		NgheNghiep = @NgheNghiep,
		HeDaoTao_DaiHoc = @HeDaoTao_DaiHoc,
		HeDaoTao_ThacSi = @HeDaoTao_ThacSi
	WHERE StudentID = @StudentID

	---------------------------------------
	---------- Đồng bộ với Bước 9 ---------
	DECLARE @Process_Student_ID INT
	DECLARE @Xet_TN_Task_ID_NC INT = 9
	DECLARE @Xet_TN_Task_ID_UD INT = 26
	DECLARE @Flow_ID INT
	
	SELECT @Process_Student_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1, 4) AND Process_Student_Status <> 'X'
	
	SELECT @Flow_ID = Flow_ID
	FROM Flow
	WHERE Process_Student_ID = @Process_Student_ID AND Task_ID IN (@Xet_TN_Task_ID_NC, @Xet_TN_Task_ID_UD)
	
	UPDATE fd 
	SET fd.Text_Content = @Loai_NgoaiNgu_DauVao
	FROM Flow_Detail fd
	INNER JOIN Task_Detail td ON td.Task_Detail_ID = fd.Task_Detail_ID
	WHERE fd.Flow_ID = @Flow_ID AND td.FieldName = 'TenNgoaiNguDauRa'
END
