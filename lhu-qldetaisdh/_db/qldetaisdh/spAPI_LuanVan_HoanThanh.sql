
CREATE PROC [dbo].[spAPI_LuanVan_HoanThanh]
@StudentID VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @Process_ID INT;
	SELECT @Process_ID = A.Process_ID 
	FROM Process_Student  A INNER JOIN Process B ON A.Process_ID = B.Process_ID
	WHERE Student_ID = @StudentID AND B.Process_Action = 1 AND USE_YN =1

	DECLARE @ThesisName NVARCHAR(500)
	DECLARE @ThesisesProf1 NVARCHAR(500)
	DECLARE @ThesisesProf2 NVARCHAR(500)

	SELECT TOP 1 @ThesisName = Text_Content
	FROM Flow a INNER JOIN Flow_Detail b on a.Flow_ID = b.Flow_ID and b.use_yn = 1 
				INNER JOIN Task_Detail c on b.Task_Detail_ID = c.Task_Detail_ID AND c.Fieldname = 'ThesisName'
				INNER JOIN Process_Student P ON A.Student_ID = P.Student_ID AND P.use_yn = 1
			WHERE a.use_yn =1 AND A.Student_ID = @StudentID AND P.Process_ID = @Process_ID 
	
	SELECT TOP 1 @ThesisesProf1 = Text_Content
	FROM Flow a INNER JOIN Flow_Detail b on a.Flow_ID = b.Flow_ID and b.use_yn = 1 
				INNER JOIN Task_Detail c on b.Task_Detail_ID = c.Task_Detail_ID AND c.Fieldname = 'ThesisesProf1'
				INNER JOIN Process_Student P ON A.Student_ID = P.Student_ID AND P.use_yn = 1
			WHERE a.use_yn =1 AND A.Student_ID = @StudentID AND P.Process_ID = @Process_ID 

	SELECT TOP 1 @ThesisesProf2 = Text_Content
	FROM Flow a INNER JOIN Flow_Detail b on a.Flow_ID = b.Flow_ID and b.use_yn = 1 
				INNER JOIN Task_Detail c on b.Task_Detail_ID = c.Task_Detail_ID AND c.Fieldname = 'ThesisesProf2'
				INNER JOIN Process_Student P ON A.Student_ID = P.Student_ID AND P.use_yn = 1
			WHERE a.use_yn =1 AND A.Student_ID = @StudentID AND P.Process_ID = @Process_ID 

	INSERT INTO Thesises([ThesisName], [ThesisMajor], [ThesisStudent], [ThesisProf1], [ThesisProf2], [ThesisYear], [StudentID],[CreateUser],[CreateTime] )
	SELECT @ThesisName, S.TenNganh, S.HoSV + ' ' + S.TenSV, @ThesisesProf1, @ThesisesProf2, YEAR(GETDATE()), @StudentID, @SYS_UserID, GETDATE()
	FROM StudentInfo S WHERE S.StudentID = @StudentID

END