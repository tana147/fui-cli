CREATE PROCEDURE spAPI_GetSumary_GiaoBai
as
begin
	DECLARE @TongSoBaiTap int = 0
	DECLARE @TongSoBaiHoc int = 0

	SELECT @TongSoBaiTap = COUNT(AssignmentID)FROM tblEL_Assignments where CreateUser <> 'NA0000022' and IsDeleted = 0
	SELECT @TongSoBaiHoc = COUNT(LessonID) FROM tblEL_Lessons where CreateUser <> 'NA0000022' and IsDeleted = 0


	SELECT @TongSoBaiTap As TongSoBaiTap, @TongSoBaiHoc As TongSoBaiHoc
end