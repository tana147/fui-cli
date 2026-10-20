-- [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien] 37,9
create PROC [dbo].[spAPI_HoiDong_DeTai_Get_ThanhVien_BK]
@NganhID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	-- Tạo bảng tạm
	IF OBJECT_ID('tempdb..#TMPSTU') IS NOT NULL
	BEGIN
		DROP TABLE #TMPSTU
	END

	CREATE TABLE #TMPSTU  (
		Student_ID INT,
		Ho_SV NVARCHAR(255),
		Ten_SV NVARCHAR(255),
		Lop_ID VARCHAR(9),
		Nganh_ID INT,
		Ten_Nganh NVARCHAR(255),
		Nien_Khoa VARCHAR(255),
		Email VARCHAR(300),
		PhoneNumber VARCHAR(20),
		Thesis_Name NVARCHAR(255),
		Thesises_Prof1 NVARCHAR(255),
		Thesises_Prof2 NVARCHAR(255)
	);

	-- Chèn dữ liệu vào bảng tạm
	INSERT INTO #TMPSTU (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa,  Thesis_Name, Thesises_Prof1, Thesises_Prof2)
	-- Chọn thông tin sinh viên và thông tin luận văn
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		f.Email, 
		f.PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ThesisName AS Thesis_Name,
		ThesisesProf1 AS Thesises_Prof1,
		ThesisesProf2 AS Thesises_Prof2
	FROM 
		flow_detail a 
		-- Kết nối với task_detail để lấy thông tin nhiệm vụ
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameDefend' --b.fieldname ='QDThanhLapHoiDongConfirm'
		-- Kết nối với flow để lấy thông tin flow
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1

		-- Kết nối với StudentInfo để lấy thông tin sinh viên
		INNER JOIN StudentInfo d ON c.student_id = d.studentID
		-- Kết nối với truy vấn phụ để lấy thông tin luận văn
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisNameDefend' THEN text_content ELSE ' ' END) ThesisName,
				--Email, PhoneNumber
				MAX(CASE WHEN fieldname='Email' THEN text_content ELSE ' ' END) Email,
				MAX(CASE WHEN fieldname='PhoneNumber' THEN text_content ELSE ' ' END) PhoneNumber,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				-- Kết nối với task_detail để lấy thông tin nhiệm vụ
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameDefend','Email', 'PhoneNumber', 'ThesisesProf1', 'ThesisesProf2') 
				-- Kết nối với flow để lấy thông tin flow
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
			WHERE 
				a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON c.student_id = f.student_id
	WHERE 
		a.flow_detail_status IN ('P','C')
		AND 
		a.use_yn = 1
	UNION
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		f.Email, 
		f.PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ThesisName AS Thesis_Name,
		f.ThesisesProf1 AS Thesises_Prof1,
		f.ThesisesProf2 AS Thesises_Prof2
	FROM 
		flow_detail a 
		-- Kết nối với task_detail để lấy thông tin nhiệm vụ
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName' --b.fieldname ='QDThanhLapHoiDongConfirm'
		-- Kết nối với flow để lấy thông tin flow
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1

		-- Kết nối với StudentInfo để lấy thông tin sinh viên
		-- Code gốc: INNER JOIN StudentInfo d ON c.student_id = d.studentID and d.NganhID = 102
		INNER JOIN StudentInfo d ON c.student_id = d.studentID and d.NganhID IN (102, 106)
		-- Kết nối với truy vấn phụ để lấy thông tin luận văn
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName,
				--Email, PhoneNumber
				NULL Email,
				NULL PhoneNumber,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				-- Kết nối với task_detail để lấy thông tin nhiệm vụ
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisName', 'ThesisesProf1','ThesisesProf2') 
				-- Kết nối với flow để lấy thông tin flow
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
			WHERE a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON c.student_id = f.student_id
			 -- Lấy thông tin ThesisesProf1 và trạng thái flow_detail_status
		LEFT JOIN (
			SELECT 
				c.student_id, 
				a.text_content AS ThesisesProf1,
				c.Flow_Status AS Flow_Status,
				a.Flow_ID
			FROM 
				flow_detail a
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id
				INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE 
				b.fieldname = 'fileLyLichKhoaHoc' AND a.use_yn = 1
		) AS Prof1Data ON d.studentID = Prof1Data.student_id
	WHERE 
		Prof1Data.Flow_Status IN ('P','C')
		AND a.use_yn = 1 


	SELECT 
		ROW_NUMBER() OVER (ORDER BY Student_ID) AS 'STT'
		
		, Student_ID 
		, Ho_SV 
		, Ten_SV 
		, Lop_ID 
		, Nganh_ID 
		, Ten_Nganh 
		, Nien_Khoa 
		, Email
		, PhoneNumber
		, Thesis_Name 
		, G1.GiangVienID AS GiangVienID1
		, Thesises_Prof1 
		, G2.GiangVienID AS GiangVienID2
		, Thesises_Prof2
		, D.Decision_ID
		, D.Decision_SoQD
		, D.Decision_NgayQD
		, D.Decision_ThangQD
		, D.Decision_NamQD
		, H.HoiDongID
		, H.KetQuaHoiDong
		, H.NhanXet
		, H.DiemHoiDong
		, H.HoiDong_Status
		, D.Decision_Status
		, H.ThoiGianBaoVe
		, H.GiangVienID AS ThanhVienHoiDong_ID
		, H.HocViHocHam AS ThanhVienHoDong_HocViHocHam
		, H.HoTenGiangVien AS ThanhVienHoiDong_HoTen
		, H.ChucTrach AS ThanhVienHoiDong_ChucTrach
		FROM #TMPSTU T
			LEFT JOIN (SELECT H.HoiDongID, H.Decision_ID, H.KetQuaHoiDong, H.NhanXet, H.DiemHoiDong, H.HoiDong_Status, H.ThoiGianBaoVe, H.StudentID, TV.GiangVienID, TV.HocViHocHam, TV.HoTenGiangVien, TV.ChucTrach FROM HoiDong H INNER JOIN HoiDongThanhVien TV ON H.HoiDongID = TV.HoiDongID WHERE TV.Is_Xoa = 0 ) AS H ON H.StudentID = T.Student_ID 
			INNER JOIN Decision D ON D.Decision_ID = H.Decision_ID AND  D.Decision_Status <> 10
			LEFT JOIN GiangVien G1 ON T.Thesises_Prof1 = G1.HocViHocHam +'. ' + G1.HoTenGiangVien AND T.Nganh_ID = G1.NganhID AND G1.Is_Xoa = 0
			LEFT JOIN GiangVien G2 ON T.Thesises_Prof2 = G2.HocViHocHam +'. ' + G2.HoTenGiangVien AND T.Nganh_ID = G2.NganhID AND G2.Is_Xoa = 0
			WHERE (Nganh_ID = @NganhID) OR (@NganhID = 0)
	


END

--select * from HoiDongThanhVien where HoiDongID = 206
