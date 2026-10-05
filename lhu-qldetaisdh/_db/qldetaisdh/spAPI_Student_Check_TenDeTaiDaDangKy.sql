CREATE PROC [dbo].[spAPI_Student_Check_TenDeTaiDaDangKy] --'922000041'
@Student_ID VARCHAR(9)
AS
BEGIN
	SELECT FD.Text_Content
	FROM FLOW F 
		INNER JOIN Flow_Detail FD ON F.Flow_ID = FD.Flow_ID AND F.Student_ID = @Student_ID
		INNER JOIN Task_Detail TD ON FD.Task_Detail_ID = TD.Task_Detail_ID
		INNER JOIN Process_Student S ON F.Student_ID = S.Student_ID  
		INNER JOIN Process P ON P.Process_ID = S.Process_ID
		WHERE TD.FieldName = 'ThesisName' AND P.Process_Action = 1 AND S.Process_Student_Status <>'X' AND S.use_yn = 1
		AND F.use_yn = 1 AND FD.use_yn = 1

END

