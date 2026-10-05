CREATE PROC [dbo].[spAPI_Get_NienKhoa_StudentWaitForThesisConfirm]-- 1, 37
@Process_ID INT,
@Nganh_ID INT
AS
BEGIN
	 select  NienKhoa AS Nien_Khoa
	
	from flow_detail a INNER JOIN task_detail b on a.task_id = b.task_id and a.task_detail_id = b.task_detail_id and b.fieldname ='ThesisConfirm'
					   INNER JOIN flow c on a.flow_id = c.flow_id and c.process_id = @Process_ID  and c.use_yn = 1
					   INNER JOIN StudentInfo d on c.student_id = d.studentID AND ( D.NganhID = @Nganh_ID OR @Nganh_ID = 0)
					   LEFT JOIN (select c.Student_id, MAX(CASE WHEN fieldname='ThesisName' then text_content else ' ' end) ThesisName,max(case when fieldname='ThesisesProf1' then text_content else ' ' end) ThesisesProf1
									from flow_detail a INNER JOIN task_detail b on a.task_id = b.task_id and a.task_detail_id = b.task_detail_id and b.fieldname in('ThesisName','ThesisesProf1') 
													   INNER JOIN flow c on a.flow_id = c.flow_id and c.process_id = @Process_ID and c.use_yn = 1
									where   a.use_yn = 1 --AND a.flow_detail_status ='C' 
									group by c.student_id
								   ) f on c.student_id = f.student_id
	where  a.use_yn = 1-- AND a.flow_detail_status ='P'

END