CREATE PROC [dbo].[spAPI_HoiDong_DeTai_Get] --  0,9
@NganhID INT,
@sys_SystemRight INT,
@BacDaoTao VARCHAR(10)
WITH RECOMPILE
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @MsgError NVARCHAR(500);
	IF (@sys_SystemRight NOT IN (1, 2, 3, 9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này ';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END

	SET @NganhID = ISNULL(@NganhID, 0);
	SET @BacDaoTao = UPPER(ISNULL(NULLIF(LTRIM(RTRIM(@BacDaoTao)), ''), 'THS'));

	-- Tạo bảng tạm
	IF OBJECT_ID('tempdb..#TMPSTU') IS NOT NULL
	BEGIN
		DROP TABLE #TMPSTU;
	END

	CREATE TABLE #TMPSTU (
		Student_ID VARCHAR(20) NOT NULL,
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

	-- 1 & 2. Khối THẠC SĨ (Chỉ thực thi khi cần dữ liệu Thạc sĩ)
	IF (@BacDaoTao IN ('THS', 'ALL'))
	BEGIN
		-- 1. Thạc sĩ - Nghiên cứu
		INSERT INTO #TMPSTU (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa, Thesis_Name, Thesises_Prof1, Thesises_Prof2)
		SELECT 
			d.StudentID AS Student_ID,
			d.HoSV AS Ho_SV,
			d.TenSV AS Ten_SV,
			d.LopID AS Lop_ID,
			d.NganhID AS Nganh_ID,
			d.TenNganh AS Ten_Nganh,
			d.Email, 
			d.SoDienThoai AS PhoneNumber,
			d.NienKhoa AS Nien_Khoa,
			f.ThesisName AS Thesis_Name,
			f.ThesisesProf1 AS Thesises_Prof1,
			f.ThesisesProf2 AS Thesises_Prof2
		FROM 
			StudentInfo d
			INNER JOIN flow c ON c.student_id = d.StudentID AND c.use_yn = 1
			INNER JOIN Process p ON c.Process_ID = p.Process_ID AND p.Process_Action = 1
			INNER JOIN flow_detail a ON a.flow_id = c.flow_id AND a.flow_detail_status IN ('P', 'C') AND a.use_yn = 1
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameDefend'
			LEFT JOIN (
				SELECT 
					c.Student_id, 
					MAX(CASE WHEN b.fieldname = 'ThesisNameDefend' THEN a.text_content ELSE ' ' END) AS ThesisName,
					MAX(CASE WHEN b.fieldname = 'ThesisesProf1' THEN a.text_content ELSE ' ' END) AS ThesisesProf1,
					MAX(CASE WHEN b.fieldname = 'ThesisesProf2' THEN a.text_content ELSE ' ' END) AS ThesisesProf2
				FROM 
					flow c
					INNER JOIN Process p ON c.Process_ID = p.Process_ID AND p.Process_Action = 1
					INNER JOIN flow_detail a ON a.flow_id = c.flow_id AND a.use_yn = 1
					INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameDefend', 'ThesisesProf1', 'ThesisesProf2') 
				WHERE 
					c.use_yn = 1
				GROUP BY 
					c.student_id
			) f ON d.StudentID = f.student_id
		WHERE 
			(d.IsXuLyHocVu = 0 OR d.IsXuLyHocVu IS NULL)
			AND (d.HeDaoTao IS NULL OR (d.HeDaoTao NOT IN ('Phd') AND d.HeDaoTao NOT LIKE N'%Tiến sĩ%'))
			AND ((d.NganhID = @NganhID) OR (@NganhID = 0));

		-- 2. Thạc sĩ - Ứng dụng
		IF (@NganhID = 0 OR @NganhID IN (102, 106))
		BEGIN
			INSERT INTO #TMPSTU (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa, Thesis_Name, Thesises_Prof1, Thesises_Prof2)
			SELECT
				d.StudentID AS Student_ID,
				d.HoSV AS Ho_SV,
				d.TenSV AS Ten_SV,
				d.LopID AS Lop_ID,
				d.NganhID AS Nganh_ID,
				d.TenNganh AS Ten_Nganh,
				d.Email, 
				d.SoDienThoai AS PhoneNumber,
				d.NienKhoa AS Nien_Khoa,
				fd.ThesisName AS Thesis_Name,
				fd.ThesisesProf1 AS Thesises_Prof1,
				fd.ThesisesProf2 AS Thesises_Prof2
			FROM StudentInfo d
			INNER JOIN (
				SELECT 
					c.student_id,
					MAX(CASE WHEN b.fieldname = 'ThesisName' THEN a.text_content ELSE ' ' END) AS ThesisName,
					MAX(CASE WHEN b.fieldname = 'ThesisesProf1' THEN a.text_content ELSE ' ' END) AS ThesisesProf1,
					MAX(CASE WHEN b.fieldname = 'ThesisesProf2' THEN a.text_content ELSE ' ' END) AS ThesisesProf2,
					MAX(CASE WHEN b.fieldname = 'fileLyLichKhoaHoc' AND c.Flow_Status IN ('P', 'C') THEN 1 ELSE 0 END) AS HasLyLich
				FROM flow c
				INNER JOIN Process p ON c.Process_ID = p.Process_ID AND p.Process_Action = 1
				INNER JOIN flow_detail a ON a.flow_id = c.flow_id AND a.use_yn = 1
				INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id 
					AND b.fieldname IN ('ThesisName', 'ThesisesProf1', 'ThesisesProf2', 'fileLyLichKhoaHoc')
				INNER JOIN StudentInfo sd ON sd.StudentID = c.student_id AND sd.NganhID IN (102, 106)
				WHERE c.use_yn = 1
				GROUP BY c.student_id
			) fd ON d.StudentID = fd.student_id
			WHERE 
				d.NganhID IN (102, 106)
				AND (d.IsXuLyHocVu = 0 OR d.IsXuLyHocVu IS NULL)
				AND (d.HeDaoTao IS NULL OR (d.HeDaoTao NOT IN ('Phd') AND d.HeDaoTao NOT LIKE N'%Tiến sĩ%'))
				AND ((d.NganhID = @NganhID) OR (@NganhID = 0))
				AND fd.HasLyLich = 1
				AND fd.ThesisName <> ' '
				AND NOT EXISTS (SELECT 1 FROM #TMPSTU t WHERE t.Student_ID = d.StudentID);
		END
	END

	-- 3. Khối TIẾN SĨ (Chỉ thực thi khi cần dữ liệu Tiến sĩ)
	IF (@BacDaoTao IN ('TS', 'ALL'))
	BEGIN
		INSERT INTO #TMPSTU (Student_ID, Ho_SV, Ten_SV, Lop_ID, Nganh_ID, Ten_Nganh, Email, PhoneNumber, Nien_Khoa, Thesis_Name, Thesises_Prof1, Thesises_Prof2)
		SELECT 
			d.StudentID AS Student_ID,
			d.HoSV AS Ho_SV,
			d.TenSV AS Ten_SV,
			d.LopID AS Lop_ID,
			d.NganhID AS Nganh_ID,
			d.TenNganh AS Ten_Nganh,
			d.Email, 
			d.SoDienThoai AS PhoneNumber,
			d.NienKhoa AS Nien_Khoa,
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
					INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
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
			AND ((d.NganhID = @NganhID) OR (@NganhID = 0))
			AND EXISTS (
				SELECT 1 FROM Process_Student ps 
				WHERE ps.Student_ID = d.StudentID 
				  AND ps.use_yn = 1 
				  AND ps.Process_Student_Status <> 'X'
			);
	END

	-- Tạo Index hỗ trợ JOIN và gom nhóm
	CREATE CLUSTERED INDEX IX_TMPSTU ON #TMPSTU(Student_ID);

	-- CTE chuẩn bị dữ liệu và mapping
	WITH ProcessClassMapping AS (
		SELECT Lop_ID, Process_ID,
			ROW_NUMBER() OVER (PARTITION BY Lop_ID ORDER BY Process_ID) AS rn_pc
		FROM Process_Class
		WHERE Process_Action IN (1, 4)
	),
	GiangVienActive AS (
		SELECT GiangVienID, (ISNULL(HocViHocHam + '. ', '') + HoTenGiangVien) AS FullName
		FROM GiangVien
		WHERE Is_Xoa = 0
	),
	RankedStudents AS (
		SELECT 
			ROW_NUMBER() OVER (
				PARTITION BY T.Student_ID, ISNULL(H.LoaiHoiDong, 0)
				ORDER BY 
				(CASE WHEN T.Email IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN T.PhoneNumber IS NOT NULL THEN 1 ELSE 0 END +
				 CASE WHEN T.Thesis_Name IS NOT NULL THEN 1 ELSE 0 END
				) DESC, H.HoiDongID DESC
			) AS rn,
			MAX(CASE WHEN H.KetQuaHoiDong = 2 THEN 1 ELSE 0 END) OVER (PARTITION BY T.Student_ID) AS HasKetQua2,
			ROW_NUMBER() OVER (ORDER BY T.Student_ID) AS 'STT',
			T.Student_ID, T.Ho_SV, T.Ten_SV, T.Lop_ID, T.Nganh_ID, T.Ten_Nganh, T.Nien_Khoa, T.Email, T.PhoneNumber,
			T.Thesis_Name,
			G1.GiangVienID AS GiangVienID1, T.Thesises_Prof1,
			G2.GiangVienID AS GiangVienID2, T.Thesises_Prof2,
			D.Decision_ID, D.Decision_SoQD, D.Decision_NgayQD, D.Decision_ThangQD, D.Decision_NamQD,
			H.HoiDongID, H.KetQuaHoiDong, H.NhanXet, H.DiemHoiDong, H.HoiDong_Status, H.LoaiHoiDong,
			D.Decision_Status, H.ThoiGianBaoVe,
			ISNULL(pc.Process_ID, 1) AS Process_ID
		FROM #TMPSTU T
		LEFT JOIN HoiDong H ON H.StudentID = T.Student_ID AND (H.Is_Xoa = 0 OR H.Is_Xoa IS NULL)
		LEFT JOIN Decision D ON D.Decision_ID = H.Decision_ID AND D.Decision_Status <> 10
		LEFT JOIN GiangVienActive G1 ON T.Thesises_Prof1 = G1.FullName
		LEFT JOIN GiangVienActive G2 ON T.Thesises_Prof2 = G2.FullName
		LEFT JOIN ProcessClassMapping pc ON pc.Lop_ID = T.Lop_ID AND pc.rn_pc = 1
	)
	SELECT 
		STT,
		Student_ID,
		Ho_SV,
		Ten_SV,
		Lop_ID,
		Nganh_ID,
		Ten_Nganh,
		Nien_Khoa,
		Email,
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
	FROM RankedStudents
	WHERE (HasKetQua2 = 1 OR rn = 1)
	ORDER BY Student_ID;
END
