-- spAPI_SDH_Get_TaskRegisterDefend  0,1,'W',9
CREATE PROC [dbo].[spAPI_SDH_Get_TaskRegister_GetByStatus]
@Nganh_Id INT,
@Process_Action INT,
@Flow_Status VARCHAR(1),
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

	--declare @tbl_StudentCanFilter AS TABLE (studentid VARCHAR(9))
	--insert into @tbl_StudentCanFilter(studentid)
	--select a.student_id --, c.Task_Code, b.Flow_Status
	--		from process_student a 
	--				inner join flow b on a.student_id = b.student_id and a.process_id = b.process_id and b.use_yn =1
	--				inner join Tasks c on b.Task_ID = c.Task_ID
	--		where a.use_yn = 1 and c.Task_Code IN ('ThS04','ThSUD04') and b.Flow_Status = 'W'

	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, TenNganh NVARCHAR(200)
						, Email VARCHAR(200)
						, SoDienThoai VARCHAR(200)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, ThesisName NVARCHAR(500)
						, ThesisesProf1 NVARCHAR(200)
						, ThesisesProf2 NVARCHAR(200)
						, File_LyLich_ID NVARCHAR(500)
						, File_LyLich_Name NVARCHAR(500)
						, File_DangKy_ID NVARCHAR(500)
						, File_DangKy_Name NVARCHAR(500)
						, File_NhanXetGVHD1_ID NVARCHAR(500)
						, File_NhanXetGVHD1_Name NVARCHAR(500)
						, File_NhanXetGVHD2_ID NVARCHAR(500)
						, File_NhanXetGVHD2_Name NVARCHAR(500)
						, File_LuanVanPDF_ID NVARCHAR(500)
						, File_LuanVanPDF_Name NVARCHAR(500)
						, File_LuanVanWORD_ID NVARCHAR(500)
						, File_LuanVanWORD_NAME NVARCHAR(500)
						, Process_Status_Register VARCHAR(5) 
						, Process_ID INT)
		INSERT INTO @tbl(Student_ID
						, Student_Name
						, TenNganh 
						, Email
						, SoDienThoai
						, Class_ID
						, Nganh_ID
						, ThesisName
						, ThesisesProf1 
						, ThesisesProf2 
						, File_LyLich_ID
						, File_LyLich_Name
						, File_DangKy_ID
						, File_DangKy_Name
						, File_NhanXetGVHD1_ID
						, File_NhanXetGVHD1_Name
						, File_NhanXetGVHD2_ID
						, File_NhanXetGVHD2_Name
						, File_LuanVanPDF_ID
						, File_LuanVanPDF_Name
						, File_LuanVanWORD_ID
						, File_LuanVanWORD_NAME
						, Process_Status_Register
						, Process_ID)
		SELECT A.Student_ID
		, HoSV+' '+TenSV
		, N.TenNganh
		, CASE WHEN T9.FieldName = 'Email' THEN F9.Text_Content END AS Email
		, CASE WHEN T8.FieldName = 'PhoneNumber' THEN F8.Text_Content END AS PhoneNumber
		, LopID 
		, B.NganhID AS Nganh_ID
		, CASE WHEN T1.FieldName = 'ThesisNameDefend' THEN F1.Text_Content END AS ThesisName
		, CASE WHEN T10.FieldName = 'ThesisesProf1' THEN F10.Text_Content END AS ThesisesProf1
		, CASE WHEN T11.FieldName = 'ThesisesProf2' THEN F11.Text_Content END AS ThesisesProf2
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_ID END AS File_LyLich_ID
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_Name END AS File_LyLich_Name
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_ID END AS File_DangKy_ID
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_Name END AS File_DangKy_Name
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_ID END AS File_NhanXetGVHD1_ID
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_Name END AS File_NhanXetGVHD1_Name
		, CASE WHEN T5.FieldName = 'fileNXGVHD2' THEN F5.File_ID END AS File_NhanXetGVHD2_ID
		, CASE WHEN T5.FieldName = 'fileNXGVHD2' THEN F5.File_Name END AS File_NhanXetGVHD2_Name
		, CASE WHEN T6.FieldName = 'fileLuanVanPDF' THEN F6.File_ID END AS File_LuanVanPDF_ID
		, CASE WHEN T6.FieldName = 'fileLuanVanPDF' THEN F6.File_Name END AS File_LuanVanPDF_Name
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_ID END AS File_LuanVanWORD_ID
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_Name END AS File_LuanVanWORD_NAME
		, D.Flow_Status AS Process_Status_Register
		, A.Process_ID
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Nganh N ON B.NganhID = N.NganhID
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D1 ON D1.Process_ID = C.Process_ID 
							AND D1.Student_ID = A.Student_ID  
							AND D1.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D2 ON D2.Process_ID = C.Process_ID 
							AND D2.Student_ID = A.Student_ID  
							AND D2.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisNameDefend' AND F1.Text_Content <> '' 
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'fileLyLichKhoaHoc'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDangKyBaoVe'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'fileNXGVHD1'
			INNER JOIN Flow_Detail F5 ON F5.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T5 ON T5.Task_Detail_ID = F5.Task_Detail_ID AND T5.FieldName = 'fileNXGVHD2'
			INNER JOIN Flow_Detail F6 ON F6.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T6 ON T6.Task_Detail_ID = F6.Task_Detail_ID AND T6.FieldName = 'fileLuanVanPDF'
			INNER JOIN Flow_Detail F7 ON F7.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T7 ON T7.Task_Detail_ID = F7.Task_Detail_ID AND T7.FieldName = 'fileLuanVanWORD'
			INNER JOIN Flow_Detail F8 ON F8.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T8 ON T8.Task_Detail_ID = F8.Task_Detail_ID AND T8.FieldName = 'PhoneNumber'
			INNER JOIN Flow_Detail F9 ON F9.Flow_ID = D1.Flow_ID 
			INNER JOIN Task_Detail T9 ON T9.Task_Detail_ID = F9.Task_Detail_ID AND T9.FieldName = 'Email'
			INNER JOIN Flow_Detail F10 ON F10.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T10 ON T10.Task_Detail_ID = F10.Task_Detail_ID AND T10.FieldName = 'ThesisesProf1' 
			INNER JOIN Flow_Detail F11 ON F11.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T11 ON T11.Task_Detail_ID = F11.Task_Detail_ID AND T11.FieldName = 'ThesisesProf2'
			
	WHERE  A.use_yn = 1 
	AND ( @Nganh_ID = 0 OR B.NganhID = @Nganh_ID)
	--	AND (E.Task_Code = 'ThS01.1' OR E.Task_Code = 'ThSUD01.1')
		AND D.Flow_Status IN  (@Flow_Status)
		

	UNION
SELECT DISTINCT A.Student_ID
		, HoSV+' '+TenSV
		, N.TenNganh
		, NULL AS  Email
		, NULL AS  PhoneNumber
		, LopID 
		, B.NganhID AS Nganh_ID
		, CASE WHEN T1.FieldName = 'ThesisName' THEN F1.Text_Content END AS ThesisName
		, CASE WHEN T10.FieldName = 'ThesisesProf1' THEN F10.Text_Content END AS ThesisesProf1
		, CASE WHEN T11.FieldName = 'ThesisesProf2' THEN F11.Text_Content END AS ThesisesProf2
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_ID END AS File_LyLich_ID
		, CASE WHEN T2.FieldName = 'fileLyLichKhoaHoc' THEN F2.File_Name END AS File_LyLich_Name
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_ID END AS File_DangKy_ID
		, CASE WHEN T3.FieldName = 'fileDangKyBaoVe' THEN F3.File_Name END AS File_DangKy_Name
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_ID END AS File_NhanXetGVHD1_ID
		, CASE WHEN T4.FieldName = 'fileNXGVHD1' THEN F4.File_Name END AS File_NhanXetGVHD1_Name
		, NULL AS File_NhanXetGVHD2_ID
		, NULL AS File_NhanXetGVHD2_Name
		, NULL AS File_LuanVanPDF_ID
		, NULL AS File_LuanVanPDF_Name
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_ID END AS File_LuanVanWORD_ID
		, CASE WHEN T7.FieldName = 'fileLuanVanWORD' THEN F7.File_Name END AS File_LuanVanWORD_NAME
		, D2.Flow_Status AS Process_Status_Register
		, A.Process_ID
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = 1 
			INNER JOIN Nganh N ON B.NganhID = N.NganhID
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D1 ON D1.Process_ID = C.Process_ID 
							AND D1.Student_ID = A.Student_ID  
							AND D1.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D2 ON D2.Process_ID = C.Process_ID 
							AND D2.Student_ID = A.Student_ID  
							AND D2.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D3 ON D3.Process_ID = C.Process_ID 
							AND D3.Student_ID = A.Student_ID  
							AND D3.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Flow D4 ON D4.Process_ID = C.Process_ID 
							AND D4.Student_ID = A.Student_ID  
							AND D4.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID

			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisName' AND F1.Text_Content <> '' 
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'fileLyLichKhoaHoc'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDangKyBaoVe'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'fileNXGVHD1'
			--INNER JOIN Flow_Detail F5 ON F5.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T5 ON T5.Task_Detail_ID = F5.Task_Detail_ID AND T5.FieldName = 'fileNXGVHD2'
			--INNER JOIN Flow_Detail F6 ON F6.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T6 ON T6.Task_Detail_ID = F6.Task_Detail_ID AND T6.FieldName = 'fileLuanVanPDF'
			
			
			INNER JOIN Flow_Detail F7 ON F7.Flow_ID = D2.Flow_ID 
			INNER JOIN Task_Detail T7 ON T7.Task_Detail_ID = F7.Task_Detail_ID AND T7.FieldName = 'fileLuanVanWORD'
			--INNER JOIN Flow_Detail F8 ON F8.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T8 ON T8.Task_Detail_ID = F8.Task_Detail_ID AND T8.FieldName = 'PhoneNumber'
			--INNER JOIN Flow_Detail F9 ON F9.Flow_ID = D1.Flow_ID 
			--INNER JOIN Task_Detail T9 ON T9.Task_Detail_ID = F9.Task_Detail_ID AND T9.FieldName = 'Email'
			INNER JOIN Flow_Detail F10 ON F10.Flow_ID = D3.Flow_ID 
			INNER JOIN Task_Detail T10 ON T10.Task_Detail_ID = F10.Task_Detail_ID AND T10.FieldName = 'ThesisesProf1' 
			INNER JOIN Flow_Detail F11 ON F11.Flow_ID = D4.Flow_ID 
			INNER JOIN Task_Detail T11 ON T11.Task_Detail_ID = F11.Task_Detail_ID AND T11.FieldName = 'ThesisesProf2'
	WHERE  A.use_yn = 1
	AND (@Nganh_ID = 0 OR B.NganhID = @Nganh_ID)
	-- Nam sửa
	--AND E.Task_Code = 'ThSUD01.3'
	AND 	 D2.Flow_Status IN  (@Flow_Status)
	-- Nam thêm
	AND EXISTS (
        SELECT 1 FROM Flow F
        WHERE F.Process_ID = C.Process_ID
          AND F.Student_ID = A.Student_ID
          AND F.Process_Student_ID = A.Process_Stu_ID
		  -- Task_ID = 3 & 21 là Bước 4. Ra QĐ giao đề tài
          AND F.Task_ID IN (3, 21)
		  -- Flow_Status của Bước 4 phải là C
          AND F.Flow_Status = 'C'
	);

	-- Lọc các rows bị trùng
	WITH CTE AS (
	SELECT 
		  ROW_NUMBER() OVER (PARTITION BY Student_ID ORDER BY Student_ID DESC) AS rn
		, Student_ID
		, Student_Name
		, t2.Email
		, t2.SoDienThoai
		, Class_ID
		, Nganh_ID
		, t2.TenNganh
		, ThesisName
		, ThesisesProf1
		, ThesisesProf2
		, File_LyLich_ID
		, File_LyLich_Name
		, File_DangKy_ID
		, File_DangKy_Name
		, File_NhanXetGVHD1_ID
		, File_NhanXetGVHD1_Name
		, File_NhanXetGVHD2_ID
		, File_NhanXetGVHD2_Name
		, File_LuanVanPDF_ID
		, File_LuanVanPDF_Name
		, File_LuanVanWORD_ID
		, File_LuanVanWORD_NAME
		, Process_Status_Register
		, t2.Process_ID
		, S.NienKhoa
	FROM @tbl t2 
	INNER JOIN StudentInfo S ON S.StudentID = t2.Student_ID 
	)
	SELECT 
		  ROW_NUMBER() OVER (ORDER BY Student_ID DESC) AS STT
		, ct.Student_ID
		, Student_Name
		, ct.Email
		, ct.SoDienThoai
		, Class_ID
		, Nganh_ID
		, ct.TenNganh
		, ThesisName
		, ThesisesProf1
		, ThesisesProf2
		, File_LyLich_ID
		, File_LyLich_Name
		, File_DangKy_ID
		, File_DangKy_Name
		, File_NhanXetGVHD1_ID
		, File_NhanXetGVHD1_Name
		, File_NhanXetGVHD2_ID
		, File_NhanXetGVHD2_Name
		, File_LuanVanPDF_ID
		, File_LuanVanPDF_Name
		, File_LuanVanWORD_ID
		, File_LuanVanWORD_NAME
		, Process_Status_Register
		, Process_ID
		, ct.NienKhoa
	FROM CTE ct
	INNER JOIN StudentInfo si ON si.StudentID = ct.Student_ID
	WHERE rn = 1
	AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	ORDER BY Nganh_ID ASC
	
	-- Backup code 2
	--SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY  Student_ID DESC) AS STT
	--, Student_ID
	--, Student_Name
	--, t2.Email
	--, t2.SoDienThoai
	--, Class_ID
	--, Nganh_ID
	--, t2.TenNganh
	--, ThesisName
	--, ThesisesProf1
	--, ThesisesProf2
	--, File_LyLich_ID
	--, File_LyLich_Name
	--, File_DangKy_ID
	--, File_DangKy_Name
	--, File_NhanXetGVHD1_ID
	--, File_NhanXetGVHD1_Name
	--, File_NhanXetGVHD2_ID
	--, File_NhanXetGVHD2_Name
	--, File_LuanVanPDF_ID
	--, File_LuanVanPDF_Name
	--, File_LuanVanWORD_ID
	--, File_LuanVanWORD_NAME
	--, Process_Status_Register
	--, t2.Process_ID
	--, S.NienKhoa
	--FROM @tbl t2 
	--INNER JOIN StudentInfo S ON S.StudentID = t2.Student_ID 
	--ORDER BY Nganh_ID ASC

	--backup code 1
	--FROM @tbl t2 
	--ORDER BY Nganh_ID ASC
END