
CREATE PROC [dbo].[spAPI_Admin_Flow_Get]
AS
BEGIN

	CREATE TABLE #Task_Task_Temp ( Task_Task_ID INT, Task_Parent INT, Task_ID INT, Seq INT, Task_Require TINYINT)
	;WITH RecursiveTasks AS (
		SELECT Task_Task_ID, Task_Parent, Task_ID, Seq, Task_Require
		FROM TASK_TASK
		WHERE Task_Parent = 1 -- Điểm bắt đầu (Task_Parent = 1)
		UNION ALL
		SELECT child.Task_Task_ID, child.Task_Parent, child.Task_ID, child.Seq, child.Task_Require
		FROM TASK_TASK child
		INNER JOIN RecursiveTasks parent ON child.Task_Parent = parent.Task_ID
	)
	
	

	INSERT INTO #Task_Task_Temp ( Task_Task_ID, Task_Parent, Task_ID, Seq, Task_Require )
	SELECT Task_Task_ID, Task_Parent, Task_ID, Seq, Task_Require FROM RecursiveTasks
	
	SELECT * FROM Process WHERE Process_ID IN (1, 4)

	SELECT * FROM #Task_Task_Temp ORDER BY Seq
	

	SELECT tasks.*, 0 AS SEQ FROM tasks where Task_ID = 1 
	UNION ALL
	SELECT T.*, X.Seq FROM #Task_Task_Temp X 
				INNER JOIN Tasks T on X.Task_ID = T.Task_ID
	ORDER BY SEQ

		

	SELECT TDL.* FROM Task_Detail TDL INNER JOIN #Task_Task_Temp T ON TDL.Task_ID = T.Task_ID ORDER BY T.Seq, TDL.Task_Detail_Seq;
    --- Cây task tiến sĩ, Tân thêm ngày 3/7/2026 14h
    with tree  as (
        SELECT Task_Task_ID, Task_Parent, Task_ID, Seq, Task_Require
		FROM TASK_TASK
		WHERE Task_Parent = 39
    )
    SELECT tasks.*, 0 AS SEQ FROM tasks where Task_ID = 39
	UNION ALL
    select b.*, a.Seq From tree a inner join tasks b on a.Task_ID = b.Task_ID

END

