CREATE PROC [dbo].[spAPI_HoiDong_ClearData]
@StudentID VARCHAR(9)
AS
BEGIN

	--DELETE Flow_Detail WHERE Flow_ID  IN (SELECT Flow_ID FROM FLOW  WHERE Student_ID = @StudentID)
 --   DELETE FLOW  WHERE Student_ID = @StudentID
	--DELETE Process_Student WHERE Student_ID = @StudentID
	--DELETE StudentInfo WHERE StudentID = @StudentID
	select 1
END