CREATE PROC [dbo].[spAPI_Theise_Upd_Prof]
@Student_ID VARCHAR(9),
@ThesisesProf1 NVARCHAR(200),
@ThesisesProf2 NVARCHAR(200),
@sys_UserID VARCHAR(9),
@sys_GroupID INT,
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

	DECLARE @Process_id int, @flow_id int, @task_id int,@task_detail_id int, @Fieldname varchar(50);

	SELECT @Process_id = a.Process_id
			, @flow_id = a.flow_id
			, @task_id = a.task_id 
			, @task_detail_id = b.task_detail_id
	FROM Flow a INNER JOIN Flow_Detail b ON a.Flow_ID = b.Flow_ID and b.use_yn = 1 and a.Student_ID = @Student_ID
					INNER JOIN Task_Detail c ON b.Task_Detail_ID = c.Task_Detail_ID and c.Fieldname = 'ThesisesProf1'
	WHERE a.use_yn =1
	EXEC spAPI_FlowDetail_UpdateData @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, NULL, @ThesisesProf1, NULL, NULL, NULL, @sys_UserID, @sys_GroupID 

	SELECT @Process_id = a.Process_id
			, @flow_id = a.flow_id
			, @task_id = a.task_id 
			, @task_detail_id = b.task_detail_id
	FROM Flow a INNER JOIN Flow_Detail b ON a.Flow_ID = b.Flow_ID and b.use_yn = 1 and a.Student_ID = @Student_ID
					INNER JOIN Task_Detail c ON b.Task_Detail_ID = c.Task_Detail_ID and c.Fieldname = 'ThesisesProf2'
	WHERE a.use_yn =1
	EXEC spAPI_FlowDetail_UpdateData @Student_ID, @Process_id, @flow_id, @task_id, @task_detail_id, NULL, @ThesisesProf2, NULL, NULL, NULL, @sys_UserID, @sys_GroupID 
END
