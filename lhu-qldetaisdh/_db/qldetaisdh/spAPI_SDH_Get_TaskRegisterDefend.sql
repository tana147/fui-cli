 --spAPI_SDH_Get_TaskRegisterDefend  0,1,'W',9
CREATE PROC [dbo].[spAPI_SDH_Get_TaskRegisterDefend] 
@Nganh_Id INT,
@Process_Action INT,
@Flow_Status VARCHAR(1),
@sys_SystemRight INT
AS
BEGIN
	SET NOCOUNT ON;
    
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @TaskID_DangKy_BaoVe_NC INT
	DECLARE @TaskID_DangKy_BaoVe_UD INT
	
	SELECT
		@TaskID_DangKy_BaoVe_NC = MAX(CASE WHEN Task_Code = 'ThS03' THEN Task_ID END),
		@TaskID_DangKy_BaoVe_UD = MAX(CASE WHEN Task_Code = 'ThSUD03' THEN Task_ID END)
	FROM Tasks
	WHERE Task_Description = 'signForDefendThesis'

    -- ==============================================================================================
    -- TỐI ƯU HOÁ HIỆU SUẤT TRUY VẤN
    -- Sử dụng Conditional Aggregation (Kỹ thuật Pivot) thay vì INNER JOIN bảng Detail lặp lại 11 lần
    -- Gom chung bí danh bảng Flow (D, D1, D2...) để loại bỏ hiện tượng Cartesian Cross Join Explosion
    -- ==============================================================================================
    
    -- 1. Lấy danh sách học viên đã hoàn thành (để loại trừ)
	DECLARE @tblStudentCompleted TABLE (StudentID VARCHAR(9))
	INSERT INTO @tblStudentCompleted(StudentID)
	SELECT DISTINCT A.Student_ID
	FROM Process_Student A 
    INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
    INNER JOIN Process C ON C.Process_ID = A.Process_ID
    INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
        AND D.Student_ID = A.Student_ID  
        AND D.Process_Student_ID = A.Process_Stu_ID
    INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
    WHERE E.Task_Code IN ('ThSUD05','ThS05') 
      AND D.Flow_Status = 'C'
      AND A.use_yn = 1 
      AND (B.NganhID = @Nganh_Id OR @Nganh_Id = 0)

	-- 2. Bảng tạm lưu trữ dữ liệu PIVOT
	DECLARE @PivotData TABLE (
		Student_ID VARCHAR(9),
		Process_ID INT,
		Process_Status_Register VARCHAR(5),
		Email VARCHAR(200),
		PhoneNumber VARCHAR(200),
		ThesisName NVARCHAR(500),
		ThesisesProf1 NVARCHAR(200),
		ThesisesProf2 NVARCHAR(200),
		File_LyLich_ID NVARCHAR(500),
		File_LyLich_Name NVARCHAR(500),
		File_DangKy_ID NVARCHAR(500),
		File_DangKy_Name NVARCHAR(500),
		File_NhanXetGVHD1_ID NVARCHAR(500),
		File_NhanXetGVHD1_Name NVARCHAR(500),
		File_NhanXetGVHD2_ID NVARCHAR(500),
		File_NhanXetGVHD2_Name NVARCHAR(500),
		File_LuanVanPDF_ID NVARCHAR(500),
		File_LuanVanPDF_Name NVARCHAR(500),
		File_LuanVanWORD_ID NVARCHAR(500),
		File_LuanVanWORD_NAME NVARCHAR(500)
	)

    -- 2.1. Đổ dữ liệu từ Nguồn 1 (Process_Action = @Process_Action)
    INSERT INTO @PivotData
    SELECT 
        A.Student_ID,
        A.Process_ID,
        MAX(D.Flow_Status) AS Process_Status_Register,
		B.Email,
		B.SoDienThoai,
        MAX(CASE WHEN T.FieldName = 'ThesisNameDefend' AND FD.Text_Content <> '' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'ThesisesProf1' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'ThesisesProf2' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'fileLyLichKhoaHoc' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileLyLichKhoaHoc' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileDangKyBaoVe' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileDangKyBaoVe' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD1' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD1' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD2' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD2' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileLuanVanPDF' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileLuanVanPDF' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileLuanVanWORD' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileLuanVanWORD' THEN FD.File_Name END)
    FROM Process_Student A 
    INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
    INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
    INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
        AND D.Student_ID = A.Student_ID  
        AND D.Process_Student_ID = A.Process_Stu_ID
    LEFT JOIN Flow_Detail FD ON FD.Flow_ID = D.Flow_ID
    LEFT JOIN Task_Detail T ON T.Task_Detail_ID = FD.Task_Detail_ID
    WHERE A.use_yn = 1 
      AND (B.NganhID = @Nganh_Id OR @Nganh_Id = 0)
      AND D.Flow_Status IN (@Flow_Status, 'C')
    GROUP BY 
		A.Student_ID, 
		A.Process_ID,
		B.Email,
		B.SoDienThoai

    -- 2.2. Đổ dữ liệu từ Nguồn 2 (Process_Action = 1, Task_Code = ThSUD01.3)
    -- Branch này tương đương SELECT UNION thứ 2 của query cũ (ưu tiên ThesisName cũ)
    INSERT INTO @PivotData
    SELECT 
        A.Student_ID,
        A.Process_ID,
        MAX(D.Flow_Status) AS Process_Status_Register,
        NULL AS Email,
        NULL AS PhoneNumber,
        MAX(CASE WHEN T.FieldName = 'ThesisName' AND FD.Text_Content <> '' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'ThesisesProf1' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'ThesisesProf2' THEN FD.Text_Content END),
        MAX(CASE WHEN T.FieldName = 'fileLyLichKhoaHoc' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileLyLichKhoaHoc' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileDangKyBaoVe' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileDangKyBaoVe' THEN FD.File_Name END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD1' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileNXGVHD1' THEN FD.File_Name END),
        NULL AS File_NhanXetGVHD2_ID,
        NULL AS File_NhanXetGVHD2_Name,
        NULL AS File_LuanVanPDF_ID,
        NULL AS File_LuanVanPDF_Name,
        MAX(CASE WHEN T.FieldName = 'fileLuanVanWORD' THEN FD.File_ID END),
        MAX(CASE WHEN T.FieldName = 'fileLuanVanWORD' THEN FD.File_Name END)
    FROM Process_Student A 
    INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
    INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = 1 
    INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
        AND D.Student_ID = A.Student_ID  
        AND D.Process_Student_ID = A.Process_Stu_ID
    INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
    LEFT JOIN Flow_Detail FD ON FD.Flow_ID = D.Flow_ID
    LEFT JOIN Task_Detail T ON T.Task_Detail_ID = FD.Task_Detail_ID
    WHERE A.use_yn = 1 
      AND (B.NganhID = @Nganh_Id OR @Nganh_Id = 0)
      AND E.Task_Code = 'ThSUD01.3'
      AND D.Flow_Status IN (@Flow_Status, 'C')
      AND A.Student_ID NOT IN (SELECT Student_ID FROM @PivotData)
    GROUP BY A.Student_ID, A.Process_ID

	-- 3. Truy xuất kết quả tổng đúc kết (Giữ nguyên cấu trúc trả về như cũ để FUI không lỗi hiển thị)
	SELECT ROW_NUMBER() OVER (ORDER BY t2.Student_ID DESC) AS STT
        , t2.Student_ID
        , S.HoSV + ' ' + S.TenSV AS Student_Name
        , t2.Email
        , t2.PhoneNumber AS SoDienThoai
        , S.LopID AS Class_ID
        , S.NganhID AS Nganh_ID
        , N.TenNganh
        , t2.ThesisName
        , t2.ThesisesProf1
        , t2.ThesisesProf2
        , t2.File_LyLich_ID
        , t2.File_LyLich_Name
        , t2.File_DangKy_ID
        , t2.File_DangKy_Name
        , t2.File_NhanXetGVHD1_ID
        , t2.File_NhanXetGVHD1_Name
        , t2.File_NhanXetGVHD2_ID
        , t2.File_NhanXetGVHD2_Name
        , t2.File_LuanVanPDF_ID
        , t2.File_LuanVanPDF_Name
        , t2.File_LuanVanWORD_ID
        , t2.File_LuanVanWORD_NAME
        , t2.Process_Status_Register
        , t2.Process_ID
        , S.NienKhoa
	FROM @PivotData t2 
	INNER JOIN StudentInfo S ON S.StudentID = t2.Student_ID
	INNER JOIN Nganh N ON S.NganhID = N.NganhID
	INNER JOIN Flow F ON F.Student_ID = t2.Student_ID 
		AND F.Flow_Status = @Flow_Status
		AND F.Task_ID IN (@TaskID_DangKy_BaoVe_NC, @TaskID_DangKy_BaoVe_UD)
		AND F.use_yn = 1
	WHERE t2.Student_ID NOT IN (SELECT StudentID FROM @tblStudentCompleted) 
      AND (S.IsXuLyHocVu = 0 OR S.IsXuLyHocVu IS NULL)
	ORDER BY S.NganhID ASC
END