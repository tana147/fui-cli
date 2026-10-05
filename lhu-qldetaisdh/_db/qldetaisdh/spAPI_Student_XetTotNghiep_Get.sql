CREATE PROC [dbo].[spAPI_Student_XetTotNghiep_Get]
	@Nganh_ID INT,
	@Flow_Status VARCHAR(2),
	@TrangThaiTotNghiep INT -- 0: Chưa tốt nghiệp, 1: Đã tốt nghiệp, 3: Tất cả
AS
BEGIN
	DECLARE @TaskID_ChinhSua_NC INT
	DECLARE @TaskID_ChinhSua_UD INT
	DECLARE @TaskID_TotNghiep_NC INT
	DECLARE @TaskID_TotNghiep_UD INT

	SELECT
		@TaskID_ChinhSua_NC = MAX(CASE WHEN Task_Code = 'ThS06' THEN Task_ID END),
		@TaskID_ChinhSua_UD = MAX(CASE WHEN Task_Code = 'ThSUD06' THEN Task_ID END)
	FROM Tasks
	WHERE Task_Code IN ('ThS06', 'ThSUD06')

	SELECT
		@TaskID_TotNghiep_NC = MAX(CASE WHEN Task_Description = 'completeThesis' THEN Task_ID END),
		@TaskID_TotNghiep_UD = MAX(CASE WHEN Task_Description = 'completeThesisUD' THEN Task_ID END)
	FROM Tasks
	WHERE Task_Description IN ('completeThesis', 'completeThesisUD')
	
	-- Tạo bảng tạm
	DECLARE @TempTable AS TABLE
	(
		Student_ID VARCHAR(9)
		, Ho_SV NVARCHAR(100)
		, Ten_SV NVARCHAR(100)
		, Gioi_Tinh NVARCHAR(3)
		, Ngay_Sinh VARCHAR(10)
		, Noi_Sinh NVARCHAR(200)
		, Nien_Khoa VARCHAR(10)
		, Lop_ID VARCHAR(10)
		, Nganh_ID INT
		, Ten_Nganh NVARCHAR(100)
		, DiemHoiDong FLOAT
		, SoQDLapHoiDong NVARCHAR(50)
		, NgayLapHoiDong VARCHAR(12)
		, ThoiGianBaoVe VARCHAR(10)
		, Thesis_Name NVARCHAR(500)
		, Thesises_Prof1 NVARCHAR(500)
		, Thesises_Prof2 NVARCHAR(500)
		, TenNgoaiNguDauRa NVARCHAR(200)
		, VanBangChungChiDauRa NVARCHAR(200)
		, ThoiGianCapDauRa VARCHAR(10)
		, DiaChiLienHe NVARCHAR(500)
		, ChucVu NVARCHAR(250)
		, DonViCongTac NVARCHAR (500)
		, File_HDYSH_ID VARCHAR(MAX)
		, SoCap_HDYSH VARCHAR(150)
		, NoiCap_HDYSH NVARCHAR(250)
	);

	INSERT @TempTable
	(
		Student_ID
		, Ho_SV
		, Ten_SV
		, Gioi_Tinh
		, Ngay_Sinh
		, Noi_Sinh
		, Nien_Khoa
		, Lop_ID
		, Nganh_ID
		, Ten_Nganh
		, DiemHoiDong
		, SoQDLapHoiDong
		, NgayLapHoiDong
		, ThoiGianBaoVe
		, Thesis_Name
		, Thesises_Prof1
		, Thesises_Prof2
		, TenNgoaiNguDauRa
		, VanBangChungChiDauRa
		, ThoiGianCapDauRa
		, DiaChiLienHe
		, ChucVu
		, DonViCongTac
		, File_HDYSH_ID
		, SoCap_HDYSH
		, NoiCap_HDYSH
	)
	SELECT DISTINCT si.StudentID AS Student_ID
		 , HoSV AS Ho_SV
		 , TenSV AS Ten_SV
		 , si.GioiTinh AS Gioi_Tinh
		 , si.NgaySinh AS Ngay_Sinh
		 , si.NoiSinh AS Noi_Sinh
		 , NienKhoa AS Nien_Khoa
		 , LopID AS Lop_ID
		 , NganhID AS Nganh_ID
		 , TenNganh AS Ten_Nganh
		 , hd.DiemHoiDong AS DiemHoiDong
		 , de.Decision_SoQD AS SoQDLapHoiDong
		 , de.Decision_NgayQD + '/' + de.Decision_ThangQD + '/' + de.Decision_NamQD
		 , hd.ThoiGianBaoVe AS ThoiGianBaoVe
		 , ThesisName AS Thesis_Name
		 , ThesisesProf1 AS Thesises_Prof1
		 , ThesisesProf2 AS Thesises_Prof2
		 , TenNgoaiNguDauRa AS TenNgoaiNguDauRa
		 , VanBangChungChiDauRa AS VanBangChungChiDauRa
		 , NgayCapNgoaiNguDauRa AS ThoiGianCapDauRa
		 , DiaChiLienHe
		 , ChucVu
		 , DonViCongTac
		 , File_HDYSH_ID
		 , SoCap_HDYSH
		 , NoiCap_HDYSH
	FROM Flow_Detail fd
	INNER JOIN Task_Detail tb ON fd.Task_ID = tb.Task_ID
		AND fd.Task_Detail_ID = tb.Task_Detail_ID
		--AND tb.FieldName = 'fileBaiBaoKhoaHoc'
	INNER JOIN Flow fl ON fd.Flow_ID = fl.Flow_ID 
		AND fl.use_yn = 1 
		AND fd.Flow_Detail_Status IN ('C')
	INNER JOIN StudentInfo si ON si.StudentID = fl.Student_ID
	INNER JOIN HoiDong hd ON hd.StudentID = si.StudentID AND hd.Is_Xoa = 0 AND hd.DiemHoiDong IS NOT NULL AND hd.DiemHoiDong <> ''
	INNER JOIN Decision de ON de.Decision_ID = hd.Decision_ID
	LEFT JOIN (SELECT c.Student_id
			, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
			, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
			, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
			, MAX(CASE WHEN fieldname='TenNgoaiNguDauRa' THEN text_content ELSE '' END) TenNgoaiNguDauRa
			, MAX(CASE WHEN fieldname='VanBangChungChiDauRa' THEN text_content ELSE '' END) VanBangChungChiDauRa
			, MAX(CASE WHEN fieldname='NgayCapNgoaiNguDauRa' THEN text_content ELSE '' END) NgayCapNgoaiNguDauRa
			, MAX(CASE WHEN fieldname='DiaChiLienHe' THEN text_content ELSE '' END) DiaChiLienHe
			, MAX(CASE WHEN fieldname='ChucVu' THEN text_content ELSE '' END) ChucVu
			, MAX(CASE WHEN fieldname='DonViCongTac' THEN text_content ELSE '' END) DonViCongTac
			, MAX(CASE WHEN fieldname='File_HDYSH_ID' THEN text_content ELSE '' END) File_HDYSH_ID
			, MAX(CASE WHEN fieldname='SoCap_HDYSH' THEN text_content ELSE '' END) SoCap_HDYSH
			, MAX(CASE WHEN fieldname='NoiCap_HDYSH' THEN text_content ELSE '' END) NoiCap_HDYSH
		FROM Flow_Detail a 
		INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID 
			AND a.Task_Detail_ID = b.Task_Detail_ID 
			AND b.FieldName IN('ThesisName'
								,'ThesisesProf1'
								,'ThesisesProf2'
								,'TenNgoaiNguDauRa'
								,'VanBangChungChiDauRa'
								,'NgayCapNgoaiNguDauRa'
								,'DiaChiLienHe'
								,'ChucVu'
								,'DonViCongTac'
								,'File_HDYSH_ID'
								,'SoCap_HDYSH'
								,'NoiCap_HDYSH') 
		 INNER JOIN Flow c on a.Flow_ID = c.Flow_ID  and c.use_yn = 1
		-- INNER JOIN StudenList e ON e.student_id = c.Student_ID
			WHERE   a.use_yn = 1
			GROUP BY c.Student_ID
		) f ON fl.Student_ID = f.Student_ID
	WHERE fd.use_yn = 1
	AND ( si.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	--AND (
	--    @Nganh_ID = '0' 
	--    OR si.NganhID IN (
	--        SELECT TRY_CAST(TRIM(value) AS INT) 
	--        FROM STRING_SPLIT(@Nganh_ID, ',')
	--        WHERE TRY_CAST(TRIM(value) AS INT) IS NOT NULL
	--    )
	--)
	-- Chỉ select những HV nào đã complete ở Bước 8
	AND EXISTS (
        SELECT 1
        FROM Flow f_check
        WHERE f_check.Student_ID = fl.Student_ID
          AND f_check.Task_ID IN (@TaskID_ChinhSua_NC, @TaskID_ChinhSua_UD)
          AND f_check.Flow_Status = 'C'
	)
	ORDER BY Nganh_ID, Nien_Khoa

	SELECT 
		tb.Student_ID,
		tb.Ho_SV,
		tb.Ten_SV,
		tb.Lop_ID,
		tb.Nien_Khoa,
		si.NgaySinh,
		tb.Noi_Sinh,
		si.GioiTinh,
		si.Loai_NgoaiNgu_DauVao AS TenNgoaiNguDauVao,
		si.NgoaiNgu_DauVao AS VanBangChungChiNNDauVao,
		si.NgoaiNgu_DauVao,
		tb.DiemHoiDong,
		tb.SoQDLapHoiDong,
		tb.NgayLapHoiDong,
		tb.ThoiGianBaoVe,
		tb.TenNgoaiNguDauRa,
		tb.VanBangChungChiDauRa,
		tb.ThoiGianCapDauRa,
		tb.Nganh_ID,
		tb.Ten_Nganh,
		tb.Thesis_Name,
		tb.Thesises_Prof1,
		tb.Thesises_Prof2,
		si.DanToc,
		si.QuocTich,
		si.CCCD,
		si.NgayCap_CCCD,
		si.SoDienThoai,
		si.Email,
		si.ThoiGianTotNghiep_DaiHoc,
		tb.DiaChiLienHe,
		tb.ChucVu,
		tb.DonViCongTac,
		d.Decision_ID,
		d.Decision_SoQD,
		d.Decision_NgayQD,
		d.Decision_ThangQD,
		d.Decision_NamQD,
		d.Decision_NgayQD + '/' + d.Decision_ThangQD + '/' + d.Decision_NamQD AS NgayLapQuyetDinh,
		d.Decision_Dot,
		d.Decision_NienKhoa,
		n.MaNganh,
		si.BoSungKienThuc,
		si.CongBoKhoaHoc,
		si.Nganh_DaiHoc,
		hd.ChuTich,
		hd.Pb_1,
		hd.Pb_2,
		hd.UyVien,
		hd.ThuKy,
		tb.SoCap_HDYSH AS So_HoiDongDaoDuc,
		si.Truong_DaiHoc,
		si.XepLoai
	FROM @TempTable tb
	INNER JOIN StudentInfo si ON si.StudentID = tb.Student_ID 
		AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
		AND (@TrangThaiTotNghiep = 3 OR si.IsHoanThanhThacSi = @TrangThaiTotNghiep)
	INNER JOIN Flow f ON tb.Student_ID = f.Student_ID 
		AND f.Task_ID IN (@TaskID_TotNghiep_NC, @TaskID_TotNghiep_UD) 
		AND f.Flow_Status = 'C'
		AND f.use_yn = 1
	LEFT JOIN Nganh n ON n.NganhID = si.NganhID
	LEFT JOIN Decision_Graduate dg ON dg.StudentID = tb.Student_ID
	LEFT JOIN Decision d ON d.Decision_ID = dg.Decision_ID
	LEFT JOIN (
		SELECT 
			StudentID,
			MAX(CASE WHEN ChucTrach = N'Chủ tịch'
				THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ChuTich,
			-- COALESCE trả về giá trị đầu tiên không null
			COALESCE(
				MAX(CASE WHEN ChucTrach = N'Phản biện 1'
					THEN HocViHocHam + '. ' + HoTenGiangVien END),
				MAX(CASE WHEN ChucTrach = N'Phản biện'
					THEN HocViHocHam + '. ' + HoTenGiangVien END)
			) AS Pb_1,
			MAX(CASE WHEN ChucTrach = N'Phản biện 2'
				THEN HocViHocHam + '. ' + HoTenGiangVien END) AS Pb_2,
			MAX(CASE WHEN ChucTrach = N'Ủy viên'
				THEN HocViHocHam + '. ' + HoTenGiangVien END) AS UyVien,
			MAX(CASE WHEN ChucTrach = N'Thư ký'
				THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ThuKy
		FROM HoiDongThanhVien
		WHERE Is_Xoa = 0
		GROUP BY StudentID
	) hd ON hd.StudentID = si.StudentID
END