
-- [dbo].[spAPI_SDH_Get_RootProcessing] '922000041', 1
CREATE PROCEDURE [dbo].[spAPI_SDH_Get_RootProcessing] 
@StudentId VARCHAR(9),
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

	;WITH AllSteps AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY B.Process_Student_ID ORDER BY B.Seq) AS Step_Index,
			D.Student_id,
			HoSV + ' ' + TenSV AS student_name,
			LopID AS student_classID,
			TenNganh AS Student_Department,
			HeDaoTao AS Student_Major,
			' ' AS Student_level,
			NienKhoa AS Student_Year,
			Expire_Date,
			D.Process_ID,
			B.Flow_ID,
			E.Task_Name,
			E.Task_Description,
			E.TASK_ID AS Children_Task_ID,
			B.Flow_Status,
			B.Seq
		FROM FLOW B 
		INNER JOIN PROCESS_STUDENT D 
			ON B.PROCESS_ID = D.PROCESS_ID 
			AND B.Student_ID = D.Student_ID 
			AND B.Process_Student_ID = D.Process_Stu_ID
			AND D.use_yn = 1
		INNER JOIN Process P 
			ON D.Process_ID = P.Process_ID 
		INNER JOIN Tasks E 
			ON B.Task_ID = E.Task_ID
		INNER JOIN StudentInfo f 
			ON d.Student_ID = f.StudentID 
		WHERE 
		  D.Student_ID = @StudentId 
		  AND P.Process_Action = @Process_Action
		  AND B.use_yn = 1
		GROUP BY 
			D.Student_id, 
			HoSV + ' ' + TenSV, 
			LopID, 
			TenNganh, 
			HeDaoTao, 
			NienKhoa, 
			Expire_Date, 
			E.Task_Name,
			B.Flow_ID, 
			E.Task_Description, 
			E.TASK_ID, 
			D.Process_ID, 
			B.Flow_Status,
			B.Seq,
			B.Process_Student_ID
	)
	SELECT * 
	FROM AllSteps
	WHERE Flow_Status = 'P'
	ORDER BY Seq ASC
END