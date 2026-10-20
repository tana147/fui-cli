--  [dbo].[spAPI_SDH_Get_TaskRegisterTheise_X]  0,1,'P',9
CREATE PROC [dbo].[spAPI_SDH_Get_TaskRegisterTheise_X]  -- 0,1,'P'
@Nganh_ID INT,
@Process_Action INT,
@Flow_Status VARCHAR(1),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, Student_Major NVARCHAR(100)
						, Student_Level NVARCHAR(20)
						, Student_Year	VARCHAR(10)
						, Task_ID INT
						, Task_Name NVARCHAR(500)
						, Flow_Status VARCHAR(5)
						, ThesisNameSuggest NVARCHAR(500)
						, ThesisesProfSuggest1 NVARCHAR(500)
						, isGVHDSigned NVARCHAR(10)
						, fileDKDeTai NVARCHAR(500)
						, ThesisesProf1 NVARCHAR(500)
						, ThesisesProf2 NVARCHAR(500)
						, NgayDangKy VARCHAR(10))
	INSERT INTO @tbl(Student_ID 
					, Student_Name 
					, Class_ID
					, Nganh_ID
					, Student_Major
					, Student_Level
					, Student_Year
					, Task_ID
					, Task_Name
					, Flow_Status
					, ThesisNameSuggest
					, ThesisesProfSuggest1
					, isGVHDSigned
					, fileDKDeTai
					, NgayDangKy)
	SELECT A.Student_ID
		, HoSV+' '+TenSV 
		, LopID 
		, B.NganhID AS Nganh_ID
		, TenNganh 
		, HeDaoTao 
		, NienKhoa 
		, D.TASK_ID
		, E.task_name
		, D.Flow_Status
		, CASE WHEN T1.FieldName = 'ThesisNameSuggest' THEN F1.Text_Content END AS ThesisNameSuggest
		, CASE WHEN T2.FieldName = 'ThesisesProfSuggest1' THEN F2.Text_Content END AS ThesisesProfSuggest1
		, CASE WHEN T4.FieldName = 'isGVHDSigned' THEN F4.Text_Content END AS isGVHDSigned
		, CASE WHEN T3.FieldName = 'fileDKDeTai' THEN F3.File_URL END AS FileDangKyDeTai
		, CONVERT(VARCHAR(10), D.Updated_At, 103) AS NgayDangKy
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID 
							AND D.Student_ID = A.Student_ID  
							AND D.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID
			INNER JOIN Flow_Detail F1 ON F1.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T1 ON T1.Task_Detail_ID = F1.Task_Detail_ID AND T1.FieldName = 'ThesisNameSuggest'
			INNER JOIN Flow_Detail F2 ON F2.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T2 ON T2.Task_Detail_ID = F2.Task_Detail_ID AND T2.FieldName = 'ThesisesProfSuggest1'
			INNER JOIN Flow_Detail F3 ON F3.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T3 ON T3.Task_Detail_ID = F3.Task_Detail_ID AND T3.FieldName = 'fileDKDeTai'
			INNER JOIN Flow_Detail F4 ON F4.Flow_ID = D.Flow_ID 
			INNER JOIN Task_Detail T4 ON T4.Task_Detail_ID = F4.Task_Detail_ID AND T4.FieldName = 'isGVHDSigned'

			
	WHERE  A.use_yn = 1  AND ( B.NganhID = @Nganh_ID OR @Nganh_ID = 0)
		AND (E.Task_Code = 'ThS01.1' OR E.Task_Code = 'ThSUD01.1')
		AND D.Flow_Status = @Flow_Status
		
	SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY  NgayDangKy DESC) AS STT
	, Student_ID 
	, Student_Name 
	, Class_ID
	, Student_Major
	, Student_Level
	, Student_Year
	, Flow_Status
	, ThesisNameSuggest
	, ThesisesProfSuggest1	
	, isGVHDSigned
	, fileDKDeTai
	, NgayDangKy
	, [DBO].[fnCheckSimilar](ThesisNameSuggest)
	FROM @tbl t2
	
END
