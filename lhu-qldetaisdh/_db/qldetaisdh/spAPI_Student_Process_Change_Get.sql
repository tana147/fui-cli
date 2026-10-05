CREATE PROC [dbo].[spAPI_Student_Process_Change_Get]  -- '924000008', '924000008'
@Student_ID VARCHAR(9),
@Process_Action INT,
@Sys_UserId VARCHAR(9)
AS
BEGIN
	SELECT 
		Process_Stu_ID AS Process_Student_ID,
		Process_ID,
		Student_ID,
		Process_Student_Status,
		use_yn,
		Created_At,
		Updated_At
	FROM Process_Student 
	WHERE Student_ID = @Student_ID  
	AND (
		(@Process_Action = 1 AND Process_ID IN (1, 4)) 
		OR (@Process_Action = 2 AND Process_ID IN (2, 5)) 
		OR (@Process_Action = 3 AND Process_ID = 3)
	)	
	ORDER BY Process_Stu_ID DESC
END

