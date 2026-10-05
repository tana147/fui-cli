-- [dbo].[spAPI_SDH_Get_Student_FlowStatus_NotFinish]   0, 1, 9
CREATE PROC [dbo].[spAPI_SDH_Get_Student_FlowStatus_NotFinish]  
@Nganh_ID INT,
@Process_Action INT,
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

	DECLARE @tbl AS TABLE(Student_ID VARCHAR(9)
						, Student_Name NVARCHAR(100)
						, Class_ID VARCHAR(10)
						, Nganh_ID INT
						, Student_Major NVARCHAR(100)
						, Student_Level NVARCHAR(20)
						, Student_Year	VARCHAR(10)
						, Task_ID INT
						, Task_Name NVARCHAR(500)
						, Flow_Status VARCHAR(5))
	INSERT INTO @tbl(Student_ID , Student_Name , Class_ID, Nganh_ID, Student_Major, Student_Level, Student_Year, Task_ID, Task_Name,Flow_Status)
	SELECT A.Student_ID
		, HoSV+' '+TenSV 
		, LopID 
		, B.NganhID AS Nganh_ID
		, TenNganh 
		, HeDaoTao 
		, NienKhoa 
		, D.TASK_ID
		, E.task_name
		,D.Flow_Status
	FROM Process_Student A 
			INNER JOIN StudentInfo B ON A.Student_ID = B.StudentID
			INNER JOIN Process C ON C.Process_ID = A.Process_ID AND C.Process_Action = @Process_Action 
			INNER JOIN Flow D ON D.Process_ID = C.Process_ID AND D.Student_ID = A.Student_ID  AND d.Process_Student_ID = a.Process_Stu_ID
			INNER JOIN Tasks E ON E.Task_ID = D.Task_ID AND E.Task_Code = 'ThS01.3'
	WHERE Flow_Status ='W' AND A.use_yn = 1  AND ( B.NganhID = @Nganh_ID OR @Nganh_ID = 0)
		
		

	SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS STT
	, Student_ID 
	, Student_Name 
	, Class_ID
	, Student_Major
	, Student_Level
	, Student_Year
	, Task_Name =  STUFF(
					(
						SELECT ' ' + Task_Name 
						FROM @tbl t1
						WHERE t1.Student_ID = t2.Student_ID
						FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)'), 1, 1, ''
				) 
			 , Flow_Status
	FROM @tbl t2
	INNER JOIN StudentInfo si ON si.StudentID = t2.Student_ID AND (si.IsXuLyHocVu IN (0) OR si.IsXuLyHocVu IS NULL)
END

