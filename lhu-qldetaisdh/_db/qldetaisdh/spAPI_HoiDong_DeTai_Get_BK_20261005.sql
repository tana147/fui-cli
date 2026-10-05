CREATE PROC [dbo].[spAPI_HoiDong_DeTai_Get] --  0,9
@NganhID INT,
@sys_SystemRight INT,
@BacDaoTao VARCHAR(10)
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
		Student_ID VARCHAR(20),
		Ho_SV NVARCHAR(255),
		Ten_SV NVARCHAR(255),
		Lop_ID VARCHAR(9),
		Nganh_ID VARCHAR(20),
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
	-- 1. Thạc sĩ - Nghiên cứu
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		d.Email, 
		d.SoDienThoai AS PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ThesisName AS Thesis_Name,
		ThesisesProf1 AS Thesises_Prof1,
		ThesisesProf2 AS Thesises_Prof2
	FROM 
		flow_detail a 
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameDefend'
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
		INNER JOIN StudentInfo d ON c.student_id = d.studentID
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisNameDefend' THEN text_content ELSE ' ' END) ThesisName,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameDefend','Email', 'PhoneNumber', 'ThesisesProf1', 'ThesisesProf2') 
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
	-- 2. Thạc sĩ - Ứng dụng
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
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName'
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
		INNER JOIN StudentInfo d ON c.student_id = d.studentID
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName,
				NULL Email,
				NULL PhoneNumber,
				MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE ' ' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE ' ' END) ThesisesProf2
			FROM 
				flow_detail a 
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisName', 'ThesisesProf1','ThesisesProf2') 
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID and p.Process_Action = 1
			WHERE 
				a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON c.student_id = f.student_id
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
		AND d.NganhID in (102, 106)
		AND a.use_yn = 1
	UNION
	-- 3. Tiến sĩ
	SELECT 
		d.StudentID AS Student_ID,
		HoSV AS Ho_SV,
		TenSV AS Ten_SV,
		LopID AS Lop_ID,
		NganhID AS Nganh_ID,
		TenNganh AS Ten_Nganh,
		d.Email, 
		d.SoDienThoai AS PhoneNumber,
		NienKhoa AS Nien_Khoa,
		ISNULL(f.ThesisName, N'Nghiên cứu ứng dụng chuyên sâu Tiến sĩ') AS Thesis_Name,
		f.ThesisesProf1 AS Thesises_Prof1,
		f.ThesisesProf2 AS Thesises_Prof2
	FROM 
		StudentInfo d
		LEFT JOIN (
			SELECT 
				c.Student_id, 
				MAX(CASE WHEN fieldname IN ('ThesisNameNew', 'ThesisName', 'DangKyDeTai') THEN text_content ELSE NULL END) ThesisName,
				MAX(CASE WHEN fieldname IN ('ThesisesProf1New', 'ThesisesProf1') THEN text_content ELSE NULL END) ThesisesProf1,
				MAX(CASE WHEN fieldname IN ('ThesisesProf2New', 'ThesisesProf2') THEN text_content ELSE NULL END) ThesisesProf2
			FROM 
				flow_detail a 
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameNew', 'ThesisName', 'DangKyDeTai', 'ThesisesProf1New', 'ThesisesProf2New', 'ThesisesProf1', 'ThesisesProf2') 
				INNER JOIN flow c ON a.flow_id = c.flow_id  AND c.use_yn = 1
				INNER JOIN Process p ON c.Process_ID = p.Process_ID AND p.Process_Type = 'Doctor'
			WHERE 
				a.use_yn = 1
			GROUP BY 
				c.student_id
		) f ON d.StudentID = f.student_id
	WHERE 
		(d.HeDaoTao = 'Phd' OR d.HeDaoTao LIKE N'%Tiến sĩ%')
		AND (d.IsXuLyHocVu = 0 OR d.IsXuLyHocVu IS NULL)
		AND d.LopID LIKE '__N%'
		AND EXISTS (
			SELECT 1 FROM Process_Student ps 
			WHERE ps.Student_ID = d.StudentID 
			  AND ps.use_yn = 1 
			  AND ps.Process_Student_Status <> 'X'
		);

	WITH RankedStudents AS (
		SELECT 
			ROW_NUMBER() OVER (
				PARTITION BY Student_ID, ISNULL(H.LoaiHoiDong, 0)
				ORDER BY 
				(CASE WHEN Email IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN PhoneNumber IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN Thesis_Name IS NOT NULL THEN 1 ELSE 0 END
				) DESC, H.HoiDongID DESC
			) AS rn,
			ROW_NUMBER() OVER (ORDER BY Student_ID) AS 'STT',
			Student_ID, Ho_SV, Ten_SV, T.Lop_ID, Nganh_ID, Ten_Nganh, Nien_Khoa, T.Email, PhoneNumber,
			Thesis_Name,
			G1.GiangVienID AS GiangVienID1, Thesises_Prof1,
			G2.GiangVienID AS GiangVienID2, Thesises_Prof2,
			D.Decision_ID, D.Decision_SoQD, D.Decision_NgayQD, D.Decision_ThangQD, D.Decision_NamQD,
			H.HoiDongID, H.KetQuaHoiDong, H.NhanXet, H.DiemHoiDong, H.HoiDong_Status, H.LoaiHoiDong,
			D.Decision_Status, H.ThoiGianBaoVe,
			ISNULL(pc.Process_ID, 1) AS Process_ID
		FROM #TMPSTU T
		LEFT JOIN HoiDong H ON H.StudentID = T.Student_ID
		LEFT JOIN Decision D ON D.Decision_ID = H.Decision_ID AND D.Decision_Status <> 10
		LEFT JOIN GiangVien G1 ON T.Thesises_Prof1 = G1.HocViHocHam + '. ' + G1.HoTenGiangVien AND G1.Is_Xoa = 0
		LEFT JOIN GiangVien G2 ON T.Thesises_Prof2 = G2.HocViHocHam + '. ' + G2.HoTenGiangVien AND G2.Is_Xoa = 0
		
		OUTER APPLY (
			SELECT TOP 1 pc.*
			FROM Process_Class pc
			WHERE pc.Lop_ID = T.Lop_ID
			  AND pc.Process_Action IN (1, 4)
			ORDER BY pc.Process_ID
		) pc

		WHERE 
			((Nganh_ID = @NganhID) OR (@NganhID = 0))
	)

	, StudentsWithKetQua2 AS (
		SELECT DISTINCT Student_ID
		FROM RankedStudents
		WHERE KetQuaHoiDong = 2
	)

	SELECT STT,
		Student_ID,
		Ho_SV,
		Ten_SV,
		Lop_ID,
		Nganh_ID,
		Ten_Nganh,
		Nien_Khoa,
		rk.Email,
		PhoneNumber,
		Thesis_Name,
		GiangVienID1,
		GiangVienID2,
		Thesises_Prof1,
		Thesises_Prof2,
		Decision_ID, 
		Decision_SoQD, 
		Decision_NgayQD, 
		Decision_ThangQD, 
		Decision_NamQD,
		HoiDongID, 
		KetQuaHoiDong, 
		NhanXet, 
		DiemHoiDong, 
		HoiDong_Status,
		LoaiHoiDong,
		Decision_Status, 
		ThoiGianBaoVe,
		Process_ID
	FROM RankedStudents rk
	INNER JOIN StudentInfo si ON si.StudentID = rk.Student_ID AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	WHERE 
		(Student_ID IN (SELECT Student_ID FROM StudentsWithKetQua2) OR rn = 1)
		AND (
			ISNULL(@BacDaoTao, 'THS') = 'ALL' 
			OR (ISNULL(@BacDaoTao, 'THS') = 'THS' AND ISNULL(si.HeDaoTao, '') NOT IN ('Phd') AND ISNULL(si.HeDaoTao, '') NOT LIKE N'%Tiến sĩ%') 
			OR (ISNULL(@BacDaoTao, 'THS') = 'TS' AND (ISNULL(si.HeDaoTao, '') IN ('Phd') OR ISNULL(si.HeDaoTao, '') LIKE N'%Tiến sĩ%'))
		)
	ORDER BY Student_ID;
END
