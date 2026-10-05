CREATE PROC [dbo].[spAPI_StudentInfor_Update_Import]
@JsonData NVARCHAR(MAX),

@SYS_UserID VARCHAR(9),
@Sys_GroupID INT,
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	-- Thạc sĩ giữ như cũ (SystemRight IN 2,3,9), Tiến sĩ là FunctionRight = 2
	IF (@sys_SystemRight NOT IN (2,3,9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @TempTable AS TABLE
	(
		StudentID VARCHAR(20) NOT NULL,
		DanToc NVARCHAR(50),
		Email VARCHAR(100),
		NoiSinh NVARCHAR(200),
		QuocTich NVARCHAR(150),
		CCCD VARCHAR(12),
		NgayCap_CCCD VARCHAR(20),
		Truong_DaiHoc NVARCHAR(400),
		Nganh_DaiHoc NVARCHAR(150),
		ThoiGianTotNghiep_DaiHoc VARCHAR(20),
		Truong_ThacSi NVARCHAR(400),
		Nganh_ThacSi NVARCHAR(150),
		ThoiGianTotNghiep_ThacSi VARCHAR(20),
		XepLoai NVARCHAR(120),
		NgoaiNgu_DauVao NVARCHAR(300),
		Loai_NgoaiNgu_DauVao NVARCHAR(50),
		BoSungKienThuc NVARCHAR(50),
		CongBoKhoaHoc NVARCHAR(50),
		SoDienThoai VARCHAR(15),
		GioiTinh NVARCHAR(5),
		DiaChi NVARCHAR(500),
		NoiLamViec NVARCHAR(500),
		NgheNghiep NVARCHAR(200),
		HeDaoTao_DaiHoc NVARCHAR(100),
		HeDaoTao_ThacSi NVARCHAR(100)
	);

	INSERT INTO @TempTable
	(
		StudentID,
		DanToc,
		Email,
		NoiSinh,
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
		Loai_NgoaiNgu_DauVao,
		BoSungKienThuc,
		CongBoKhoaHoc,
		SoDienThoai,
		GioiTinh,
		DiaChi,
		NoiLamViec,
		NgheNghiep,
		HeDaoTao_DaiHoc,
		HeDaoTao_ThacSi
	)
	SELECT *
	FROM OPENJSON(@JsonData)
	WITH
	(
		StudentID VARCHAR(20) '$.StudentID',
		DanToc NVARCHAR(50) '$.DanToc',
		Email VARCHAR(100) '$.Email',
		NoiSinh NVARCHAR(200) '$.NoiSinh',
		QuocTich NVARCHAR(150) '$.QuocTich',
		CCCD VARCHAR(12) '$.CCCD',
		NgayCap_CCCD VARCHAR(20) '$.NgayCap_CCCD',
		Truong_DaiHoc NVARCHAR(400) '$.Truong_DaiHoc',
		Nganh_DaiHoc NVARCHAR(150) '$.Nganh_DaiHoc',
		ThoiGianTotNghiep_DaiHoc VARCHAR(20) '$.ThoiGianTotNghiep_DaiHoc',
		Truong_ThacSi NVARCHAR(400) '$.Truong_ThacSi',
		Nganh_ThacSi NVARCHAR(150) '$.Nganh_ThacSi',
		ThoiGianTotNghiep_ThacSi VARCHAR(20) '$.ThoiGianTotNghiep_ThacSi',
		XepLoai NVARCHAR(120) '$.XepLoai',
		NgoaiNgu_DauVao NVARCHAR(300) '$.NgoaiNgu_DauVao',
		Loai_NgoaiNgu_DauVao NVARCHAR(50) '$.Loai_NgoaiNgu_DauVao',
		BoSungKienThuc NVARCHAR(50) '$.BoSungKienThuc',
		CongBoKhoaHoc NVARCHAR(50) '$.CongBoKhoaHoc',
		SoDienThoai VARCHAR(15) '$.SoDienThoai',
		GioiTinh NVARCHAR(5) '$.GioiTinh',
		DiaChi NVARCHAR(500) '$.DiaChi',
		NoiLamViec NVARCHAR(500) '$.NoiLamViec',
		NgheNghiep NVARCHAR(200) '$.NgheNghiep',
		HeDaoTao_DaiHoc NVARCHAR(100) '$.HeDaoTao_DaiHoc',
		HeDaoTao_ThacSi NVARCHAR(100) '$.HeDaoTao_ThacSi'
	)

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
	INNER JOIN @TempTable temp ON (si.StudentID = temp.StudentID OR si.MaHoSo = temp.StudentID)

	-- Update dữ liệu học viên
	UPDATE SI
	SET 
		SI.DanToc = COALESCE(tt.DanToc, SI.DanToc),
		SI.QuocTich = COALESCE(tt.QuocTich, SI.QuocTich),
		SI.GioiTinh = COALESCE(tt.GioiTinh, SI.GioiTinh),
		SI.Email = COALESCE(tt.Email, SI.Email),
		SI.NoiSinh = COALESCE(tt.NoiSinh, SI.NoiSinh),
		SI.CCCD = COALESCE(tt.CCCD, SI.CCCD),
		SI.NgayCap_CCCD = COALESCE(TRY_CONVERT(DATE, NULLIF(tt.NgayCap_CCCD, ''), 105), TRY_CONVERT(DATE, NULLIF(tt.NgayCap_CCCD, ''), 103), TRY_CAST(NULLIF(tt.NgayCap_CCCD, '') AS DATE), SI.NgayCap_CCCD),
		SI.Truong_DaiHoc = COALESCE(tt.Truong_DaiHoc, SI.Truong_DaiHoc),
		SI.Nganh_DaiHoc = COALESCE(tt.Nganh_DaiHoc, SI.Nganh_DaiHoc),
		SI.ThoiGianTotNghiep_DaiHoc = COALESCE(tt.ThoiGianTotNghiep_DaiHoc, SI.ThoiGianTotNghiep_DaiHoc),
		SI.Truong_ThacSi = COALESCE(tt.Truong_ThacSi, SI.Truong_ThacSi),
		SI.Nganh_ThacSi = COALESCE(tt.Nganh_ThacSi, SI.Nganh_ThacSi),
		SI.ThoiGianTotNghiep_ThacSi = COALESCE(tt.ThoiGianTotNghiep_ThacSi, SI.ThoiGianTotNghiep_ThacSi),
		SI.XepLoai = COALESCE(tt.XepLoai, SI.XepLoai),
		SI.NgoaiNgu_DauVao = COALESCE(tt.NgoaiNgu_DauVao, SI.NgoaiNgu_DauVao),
		SI.Loai_NgoaiNgu_DauVao = COALESCE(tt.Loai_NgoaiNgu_DauVao, SI.Loai_NgoaiNgu_DauVao),
		SI.BoSungKienThuc = COALESCE(tt.BoSungKienThuc, SI.BoSungKienThuc),
		SI.CongBoKhoaHoc = COALESCE(tt.CongBoKhoaHoc, SI.CongBoKhoaHoc),
		SI.SoDienThoai = COALESCE(tt.SoDienThoai, SI.SoDienThoai),
		SI.DiaChi = COALESCE(tt.DiaChi, SI.DiaChi),
		SI.NoiLamViec = COALESCE(tt.NoiLamViec, SI.NoiLamViec),
		SI.NgheNghiep = COALESCE(tt.NgheNghiep, SI.NgheNghiep),
		SI.HeDaoTao_DaiHoc = COALESCE(tt.HeDaoTao_DaiHoc, SI.HeDaoTao_DaiHoc),
		SI.HeDaoTao_ThacSi = COALESCE(tt.HeDaoTao_ThacSi, SI.HeDaoTao_ThacSi),
		SI.UpdateUser = @SYS_UserID,
		SI.UpdateTime = GETDATE()
	FROM StudentInfo SI
	INNER JOIN @TempTable tt ON (SI.StudentID = tt.StudentID OR SI.MaHoSo = tt.StudentID)

	---------------------------------------
	--------- Đồng bộ với Bước 9 ----------
	DECLARE @Xet_TN_Task_ID_NC INT = 9
	DECLARE @Xet_TN_Task_ID_UD INT = 26

	UPDATE fd
	SET fd.Text_Content = t.Loai_NgoaiNgu_DauVao
	FROM Flow_Detail fd
	INNER JOIN Task_Detail td 
	    ON td.Task_Detail_ID = fd.Task_Detail_ID
	INNER JOIN Flow f 
	    ON f.Flow_ID = fd.Flow_ID
	INNER JOIN Process_Student ps 
	    ON ps.Process_Stu_ID = f.Process_Student_ID
	INNER JOIN @TempTable t 
	    ON (t.StudentID = ps.Student_ID)
	WHERE td.FieldName = 'TenNgoaiNguDauRa'
	  AND f.Task_ID IN (@Xet_TN_Task_ID_NC, @Xet_TN_Task_ID_UD)
	  AND ps.Process_ID IN (1, 4)
	  AND ps.Process_Student_Status <> 'X';
END