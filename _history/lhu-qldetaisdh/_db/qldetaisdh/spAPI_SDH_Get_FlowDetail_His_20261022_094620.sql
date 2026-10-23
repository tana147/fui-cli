CREATE PROC [dbo].[spAPI_SDH_Get_FlowDetail_His]
@Flow_ID int
AS
BEGIN
	-- Nếu @Flow_ID truyền vào là Flow_ID hiện hành (chưa có trong Flow_Detail_His), tự động map sang Flow_ID lịch sử gần nhất của cùng Học viên & Task
	IF NOT EXISTS (SELECT 1 FROM Flow_Detail_His WHERE FLOW_ID = @Flow_ID)
	BEGIN
		DECLARE @StudentID varchar(20), @TaskID int
		SELECT @StudentID = PS.Student_ID, @TaskID = F.Task_ID
		FROM Flow F
		INNER JOIN Process_Student PS ON F.Process_Student_ID = PS.Process_Stu_ID
		WHERE F.Flow_ID = @Flow_ID

		IF (@StudentID IS NOT NULL)
		BEGIN
			SELECT TOP 1 @Flow_ID = Flow_ID 
			FROM Flow_His 
			WHERE Student_ID = @StudentID AND Task_ID = @TaskID 
			ORDER BY Flow_His_ID DESC
		END
	END

	SELECT Flow_Detail_ID
		, Flow_ID
		, A.Task_ID
		, B.Task_Detail_Seq
		, B.Task_Detail_ID
		, B.Task_Detail_Description
		, B.Task_Detail_Type
		, File_URL
		, File_ID
		, Text_Content
		, File_Name
		, File_Type
		, Flow_Detail_Status
		, FieldName
		, B.User_Input
		, B.Task_Detail_Display
		, B.Task_Detail_StyleDisplay
		, B.Data_Exp
		, B.UI_Component
		, B.FN_Check
		, B.[AllowNull]
		, B.AllowFileType
		, B.Task_Help
		, B.SubGroup
	FROM Flow_Detail_His A 
		INNER JOIN TASK_DETAIL B ON A.TASK_DETAIL_ID = B.TASK_DETAIL_ID
	WHERE A.FLOW_ID = @Flow_ID 
		AND A.USE_YN = 1 AND B.USE_YN = 1
	ORDER BY B.TASK_DETAIL_SEQ
END