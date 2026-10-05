-- spAPI_Get_RootFlow '921000065', 3529, 1
CREATE PROC [dbo].[spAPI_Get_RootFlow_His] 
@StudentID VARCHAR(9)
AS
BEGIN
	SELECT 
	Flow_His_ID
	,Student_ID
	,Flow_ID
	,Process_Student_ID
	,Process_ID
	,Task_Parent
	,FH.Task_ID
	,Seq
	,Task_Require
	,Flow_Status
	,LyDo
	,T.Task_Name
	,FH.Flow_Status
	FROM Flow_His FH
	INNER JOIN Tasks T ON FH.Task_ID = T.Task_ID
	WHERE Student_ID = @StudentID
	ORDER BY Seq ASC
END


