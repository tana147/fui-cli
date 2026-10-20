CREATE PROC [dbo].[spAPI_Get_StudentWaitForThesisConfirm] 
@Process_ID INT,
@Nganh_ID INT,
@Nien_Khoa VARCHAR(9)
AS
BEGIN
	SELECT d.StudentID AS Student_ID
	, HoSV AS Ho_SV
	, TenSV AS Ten_SV
	, LopID AS Lop_ID
	, NganhID AS Nganh_ID
	, TenNganh AS Ten_Nganh
	, NienKhoa AS Nien_Khoa
	, ThesisName AS Thesis_Name
	, ThesisesProf1 AS Thesises_Prof1
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
	LEFT JOIN (
		SELECT c.Student_id, 
			   MAX(CASE WHEN fieldname = 'ThesisName' THEN text_content ELSE ' ' END) AS ThesisName,
			   MAX(CASE WHEN fieldname = 'ThesisesProf1' THEN text_content ELSE ' ' END) AS ThesisesProf1
		FROM flow_detail a 
		INNER JOIN task_detail b ON a.task_id = b.task_id 
								AND a.task_detail_id = b.task_detail_id 
								AND b.fieldname IN ('ThesisName', 'ThesisesProf1') 
		INNER JOIN flow c ON a.flow_id = c.flow_id 
						 AND c.use_yn = 1
						 AND (
							 (@Process_ID IN (1, 4) AND c.process_id IN (1, 4))
							 OR c.process_id = @Process_ID 
							 OR @Process_ID = 0
						 )
		WHERE a.use_yn = 1
		GROUP BY c.student_id
	) f ON c.student_id = f.student_id
	WHERE a.use_yn = 1 
	  AND d.NienKhoa = @Nien_Khoa;
END
