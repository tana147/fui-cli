-- spAPI_Get_RootFlow '921000065', 3529, 1
CREATE PROC [dbo].[spAPI_Get_RootFlow] 
@StudentID VARCHAR(9),
@Process_Student_ID INT,
@Process_Tree INT
AS
BEGIN
	DECLARE @Process_ID INT;
	DECLARE @TASK_BEGIN INT;
	IF @StudentID = 'GV0000611' SET @StudentID = '924000233'

	IF (@Process_Student_ID IS NOT NULL AND @Process_Student_ID > 0)
	BEGIN
		SELECT @Process_ID = Process_ID, @TASK_BEGIN = TASK_BEGIN
		FROM Process_Student
		WHERE Student_ID = @StudentID AND Process_Stu_ID = @Process_Student_ID;
	END
	ELSE
	BEGIN
		SELECT @Process_ID = A.Process_ID, @TASK_BEGIN = A.TASK_BEGIN
		FROM Process_Student A INNER JOIN Process B ON A.Process_ID = B.Process_ID
		WHERE Student_ID = @StudentID AND B.PROCESS_TREE = @Process_Tree AND USE_YN = 1;
	END;

	;WITH TREE_TASK AS(
		SELECT TASK_PARENT, F.TASK_ID, SEQ, Task_Require, 0 lv, Flow_Status, F.Flow_ID, SEQ*100000 X_SEQ, PROCESS_ID, STUDENT_ID
			FROM FLOW F 
			WHERE STUDENT_ID = @StudentID 
					AND Process_ID  = @Process_ID 
					AND (
						(@Process_Student_ID > 0 AND F.Process_Student_ID = @Process_Student_ID)
						OR ((@Process_Student_ID IS NULL OR @Process_Student_ID = 0) AND F.use_yn = 1)
					)
					AND TASK_PARENT= @TASK_BEGIN
		UNION ALL
		SELECT F.TASK_PARENT, F.TASK_ID, F.SEQ, F.Task_Require*T.Task_Require , T.lv + 1 lv, F.Flow_Status, F.Flow_ID, T.X_SEQ+F.SEQ*100000/((T.LV+1)*10) X_SEQ, F.PROCESS_ID, F.STUDENT_ID
		FROM FLOW F 
		INNER JOIN TREE_TASK T on F.TASK_PARENT = T.TASK_ID 
					and F.Student_ID = @StudentID 
					AND F.Process_ID  = @Process_ID
		WHERE (
			(@Process_Student_ID > 0 AND F.Process_Student_ID = @Process_Student_ID)
			OR ((@Process_Student_ID IS NULL OR @Process_Student_ID = 0) AND F.use_yn = 1)
		)
	) 
	SELECT	PROCESS_ID, STUDENT_ID
			, A.TASK_PARENT AS Parent_Task_ID
			,B.TASK_ID AS Children_Task_ID
			, B.TASK_NAME
			, B.Task_Description
			, A.SEQ
			, A.Task_Require
			, A.LV, A.Flow_Status, A.Flow_ID
			,CASE WHEN X_SEQ = MIN(CASE WHEN FLOW_STATUS='C' THEN 10000000 WHEN A.TASK_REQUIRE = 0 AND FLOW_STATUS ='W' THEN 10000000 ELSE X_SEQ END) OVER () THEN 1 ELSE 0 END LOCK_STATUS
	FROM TREE_TASK A INNER JOIN TASKS B ON B.TASK_ID = A.TASK_ID
	ORDER BY X_SEQ 
END


