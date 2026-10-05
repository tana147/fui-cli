
CREATE PROC [dbo].[spAPI_Student_Process_Get]--  '922000041', '922000041'
@Student_ID VARCHAR(9),
@IsFull BIT, -- 1: lấy full, 0: Lấp TOP 2
@Sys_UserId VARCHAR(9)
AS
BEGIN
	DECLARE @TopRows INT = CASE WHEN @IsFull = 0 THEN 2 ELSE 1000000 END;

	SELECT TOP (@TopRows)
		ps.Process_Stu_ID AS Process_Student_ID,
		ps.Process_ID,
		ps.Student_ID,
		si.NganhID,
		ps.Process_Student_Status  
	FROM Process_Student ps
	INNER JOIN StudentInfo si ON si.StudentID = ps.Student_ID
	WHERE Student_ID = @Student_ID 
	  AND ps.Process_ID IN (1, 4)
	ORDER BY Process_Stu_ID DESC;
END
