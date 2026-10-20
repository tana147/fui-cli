CREATE PROC [dbo].[spAPI_Get_NienKhoa_StudentWaitForThesisConfirm]
@Process_ID INT,
@Nganh_ID INT
AS
BEGIN
	SELECT DISTINCT d.NienKhoa AS Nien_Khoa
	FROM flow_detail a 
	INNER JOIN task_detail b ON a.task_id = b.task_id 
							AND a.task_detail_id = b.task_detail_id 
							AND b.fieldname = 'ThesisConfirm'
	INNER JOIN flow c ON a.flow_id = c.flow_id 
					 AND c.use_yn = 1
					 AND (
						 (@Process_ID IN (1, 4) AND c.process_id IN (1, 4))
						 OR c.process_id = @Process_ID 
						 OR @Process_ID = 0
					 )
	INNER JOIN StudentInfo d ON c.student_id = d.studentID 
							AND (d.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	WHERE a.use_yn = 1
	  AND d.NienKhoa IS NOT NULL 
	  AND d.NienKhoa <> ''
	ORDER BY d.NienKhoa DESC;
END