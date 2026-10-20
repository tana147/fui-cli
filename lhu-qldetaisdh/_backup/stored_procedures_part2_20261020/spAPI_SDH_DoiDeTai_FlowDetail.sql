
CREATE PROC [dbo].[spAPI_SDH_DoiDeTai_FlowDetail]
@StudentID VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
	DECLARE @DoiDeTai_NC_Process_ID INT = 2
	DECLARE @DoiDeTai_UD_Process_ID INT = 5
	DECLARE @DoiDeTai_NC_TaskID INT = 13
	DECLARE @DoiDeTai_UD_TaskID INT = 37
	DECLARE @ThesisName_NC_New_TaskDetail_ID INT = 122
	DECLARE @ThesisProf1_NC_New_TaskDetail_ID INT = 123
	DECLARE @ThesisProf2_NC_New_TaskDetail_ID INT = 124
	DECLARE @ThesisName_UD_New_TaskDetail_ID INT = 126
	DECLARE @ThesisProf1_UD_New_TaskDetail_ID INT = 127
	DECLARE @ThesisProf2_UD_New_TaskDetail_ID INT = 128
	DECLARE @ProcessStudentID INT
	DECLARE @FlowID INT
	
	SELECT @ProcessStudentID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID 
		AND Process_ID IN (@DoiDeTai_NC_Process_ID, @DoiDeTai_UD_Process_ID)
		AND Process_Student_Status <> 'X'
	
	SELECT @FlowID = Flow_ID
	FROM Flow
	WHERE Process_Student_ID = @ProcessStudentID
	AND Task_ID IN (@DoiDeTai_NC_TaskID, @DoiDeTai_UD_TaskID)
	
	SELECT 
	    si.StudentID AS Student_ID,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisName_NC_New_TaskDetail_ID, @ThesisName_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesis_Name_New,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisProf1_NC_New_TaskDetail_ID, @ThesisProf1_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesises_Prof1_New,
	    MAX(CASE 
	        WHEN fd.Task_Detail_ID IN (@ThesisProf2_NC_New_TaskDetail_ID, @ThesisProf2_UD_New_TaskDetail_ID) 
	        THEN fd.text_content 
	    END) AS Thesises_Prof2_New
	FROM StudentInfo si
	LEFT JOIN flow_detail fd 
	    ON fd.Flow_ID = @FlowID
	    AND fd.use_yn = 1
	
	WHERE si.StudentID = @StudentID
	GROUP BY si.StudentID
END
