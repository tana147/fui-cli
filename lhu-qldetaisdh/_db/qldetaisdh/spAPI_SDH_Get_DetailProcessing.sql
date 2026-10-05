
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- [dbo].[spAPI_SDH_Get_DetailProcessing]  69
CREATE PROCEDURE [dbo].[spAPI_SDH_Get_DetailProcessing] 
@Flow_ID INT,
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
	SELECT DISTINCT D.Student_id
	,D.Process_ID
	--, HoSV+' '+TenSV student_name
	--, LopID student_classID
	--, TenNganh Student_Department
	--, HeDaoTao Student_Major
	--, ' ' Student_level
	--, NienKhoa Student_Year, Expire_Date,
	, Flow_Detail_Status
	,A.FLOW_ID, A.TASK_ID, e.task_name, A.TASK_DETAIL_ID, C.TASK_DETAIL_SEQ, si.NganhID, C.TASK_DETAIL_DESCRIPTION,C.USER_INPUT, C.FN_Check
	,C.FieldName, C.Task_Detail_Display ,A.File_ID, A.File_Name, A.File_Type, A.File_URL, A.Text_Content, C.Task_Detail_Type, C.Data_Exp, C.AllowNull
	FROM FLOW_DETAIL A inner join task_detail c on a.task_id = c.task_id and a.task_detail_id = c.task_detail_id and c.USE_YN = 1
					   INNER JOIN FLOW B ON A.FLOW_ID = B.FLOW_ID AND A.TASK_ID = B.TASK_ID AND B.Flow_Status <> 'X'
					   INNER JOIN PROCESS_STUDENT D ON B.PROCESS_ID = D.PROCESS_ID and b.student_id = d.student_id AND D.Process_Student_Status <>'X'
					   INNER JOIN StudentInfo si ON D.Student_ID = si.StudentID
					   inner join tasks e on b.task_id = e.task_id
					   inner join StudentInfo f on d.student_id = f.studentid
	-- IN ('W', 'P', 'C')  	
	WHERE FLOW_DETAIL_STATUS IN ('W', 'P', 'C')
		AND A.FLOW_ID = @Flow_ID
		AND A.use_yn = 1
	ORDER BY Task_ID, Task_Detail_Seq
END


