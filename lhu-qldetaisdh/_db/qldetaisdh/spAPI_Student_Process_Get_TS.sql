CREATE PROC [dbo].[spAPI_Student_Process_Get_TS]
@Student_ID VARCHAR(9),
@IsFull BIT, 
@Sys_UserId VARCHAR(9)
AS
BEGIN
	DECLARE @TopRows INT = CASE WHEN @IsFull = 0 THEN 2 ELSE 1000000 END;

	SELECT TOP (@TopRows)
		ps.Process_Stu_ID AS Process_Student_ID,
		ps.Process_ID,
		ps.Student_ID,
		si.NganhID,
		ps.Process_Student_Status,
		pr.Process_Action,
		pr.Process_Tree
	FROM Process_Student ps
	INNER JOIN StudentInfo si ON si.StudentID = ps.Student_ID
	INNER JOIN Process pr ON pr.Process_ID = ps.Process_ID
	WHERE ps.Student_ID = @Student_ID 
      AND ps.use_yn = 1
      AND pr.Process_Type = 'Doctor'
	ORDER BY pr.Process_Action ASC, ps.Process_Stu_ID DESC;
END