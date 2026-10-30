
CREATE PROC spAPI_EL_Lesson_Delete
	@LessonID INT,
	@SYS_USERID VARCHAR(9)
as
begin
	UPDATE tblEL_Lessons
	set
		IsDeleted = 1,
		UpdateTime = GETDATE(),
		UpdateUser = @SYS_USERID
	where LessonID = @LessonID
END
