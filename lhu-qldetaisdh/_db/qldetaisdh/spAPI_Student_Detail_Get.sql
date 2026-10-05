CREATE PROCEDURE dbo.spAPI_Student_Detail_Get
@StudentObjArr NVARCHAR(MAX),
@sys_UserID varchar(9),
@sys_GroupID int,
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

	DECLARE @TempStudentInfo AS TABLE
	(
		StudentID VARCHAR(9)
	)

	INSERT INTO @TempStudentInfo
	(
	    StudentID
	)
	SELECT
	    StudentID
	FROM OPENJSON(@StudentObjArr)
	WITH
	(
	    StudentID VARCHAR(9) '$.StudentID'
	)
	
	-------- Collect data --------------
	;WITH CollectData AS
	(
		SELECT DISTINCT
			si.StudentID,
			f.TenNgoaiNguDauRa,
			f.VanBangChungChiDauRa,
			f.NgayCapNgoaiNguDauRa AS ThoiGianCapDauRa,
			f.DiaChiLienHe,
			f.ChucVu,
			f.DonViCongTac,
			f.ThesisName,
			f.ThesisesProf1,
			f.ThesisesProf2,
			hd.DiemHoiDong
		FROM Flow_Detail fd
		INNER JOIN Task_Detail tb 
			ON fd.Task_ID = tb.Task_ID
			AND fd.Task_Detail_ID = tb.Task_Detail_ID
		INNER JOIN Flow fl 
			ON fd.Flow_ID = fl.Flow_ID 
			AND fl.use_yn = 1 
			AND fd.Flow_Detail_Status IN ('C')
		INNER JOIN StudentInfo si 
			ON si.StudentID = fl.Student_ID
		LEFT JOIN HoiDong hd 
			ON hd.StudentID = si.StudentID 
			AND hd.Is_Xoa = 0 
			AND hd.DiemHoiDong IS NOT NULL
		LEFT JOIN 
		(
			SELECT 
				c.Student_id,
				MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName,
			 	MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1,
				MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2,
				MAX(CASE WHEN b.FieldName = 'TenNgoaiNguDauRa' THEN a.Text_Content ELSE '' END) AS TenNgoaiNguDauRa,
				MAX(CASE WHEN b.FieldName = 'VanBangChungChiDauRa' THEN a.Text_Content ELSE '' END) AS VanBangChungChiDauRa,
				MAX(CASE WHEN b.FieldName = 'NgayCapNgoaiNguDauRa' THEN a.Text_Content ELSE '' END) AS NgayCapNgoaiNguDauRa,
				MAX(CASE WHEN b.FieldName = 'DiaChiLienHe' THEN a.Text_Content ELSE '' END) AS DiaChiLienHe,
				MAX(CASE WHEN b.FieldName = 'ChucVu' THEN a.Text_Content ELSE '' END) AS ChucVu,
				MAX(CASE WHEN b.FieldName = 'DonViCongTac' THEN a.Text_Content ELSE '' END) AS DonViCongTac
			FROM Flow_Detail a 
			INNER JOIN Task_Detail b 
				ON a.Task_ID = b.Task_ID 
				AND a.Task_Detail_ID = b.Task_Detail_ID 
				AND b.FieldName IN 
				(
					'TenNgoaiNguDauRa',
					'VanBangChungChiDauRa',
					'NgayCapNgoaiNguDauRa',
					'ThesisName',
					'ThesisesProf1',
					'ThesisesProf2',
					'DiaChiLienHe',
					'ChucVu',
					'DonViCongTac'
				)
			INNER JOIN Flow c 
				ON a.Flow_ID = c.Flow_ID  
				AND c.use_yn = 1
			WHERE a.use_yn = 1
			GROUP BY c.Student_ID
		) f 
			ON fl.Student_ID = f.Student_ID
		WHERE fd.use_yn = 1
	)
	
	SELECT 
		t.StudentID,
		si.HoSV,
		si.TenSV,
		si.GioiTinh,
		si.NgaySinh,
		si.TenNganh,
		si.NienKhoa,
		si.LopID,
		cd.ThesisName,
		cd.ThesisesProf1,
		cd.ThesisesProf2,
		cd.DiemHoiDong,
		si.SoDienThoai,
		si.Email,
		cd.DiaChiLienHe,
		cd.ChucVu,
		cd.DonViCongTac,
		si.Loai_NgoaiNgu_DauVao,
		cd.TenNgoaiNguDauRa,
		cd.VanBangChungChiDauRa,
		cd.ThoiGianCapDauRa
	FROM @TempStudentInfo t
	INNER JOIN StudentInfo si 
		ON si.StudentID = t.StudentID 
		AND (si.IsXuLyHocVu IN (0) OR si.IsXuLyHocVu IS NULL)
	LEFT JOIN CollectData cd 
		ON cd.StudentID = si.StudentID
END