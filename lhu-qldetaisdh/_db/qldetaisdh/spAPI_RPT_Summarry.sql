CREATE PROC [dbo].[spAPI_RPT_Summarry]
AS
BEGIN
	SELECT NienKhoa, HeDaoTaoID, HeDaoTao, process_description, COUNT(1) AS Total_Student, 
		SUM(CASE WHEN a.process_id NOT IN (2, 3) AND process_student_status = 'W' THEN 1 ELSE 0 END) AS W_Process, 
		SUM(CASE WHEN a.process_id NOT IN (2, 3) AND process_student_status = 'P' THEN 1 ELSE 0 END) AS P_Process,
		SUM(CASE WHEN a.process_id NOT IN (2, 3) AND process_student_status = 'C' THEN 1 ELSE 0 END) AS C_Process
		FROM process_student a
		-- Có 1 số MSHV không tồn tại ở studentInfo
		INNER JOIN studentInfo b ON a.student_id = b.studentid 
		INNER JOIN process c ON a.process_id = c.process_id
		WHERE a.process_id NOT IN (2, 3, 5) AND process_student_status <> 'X'
		GROUP BY NienKhoa, HeDaoTaoID, HeDaoTao, process_description;

		SELECT NienKhoa, HeDaoTaoID, HeDaoTao, process_description, COUNT(1) AS Total_Student, 
			SUM(CASE WHEN process_student_status = 'W' THEN 1 ELSE 0 END) AS W_Process,
			SUM(CASE WHEN process_student_status = 'P' THEN 1 ELSE 0 END) AS P_Process,
			SUM(CASE WHEN process_student_status = 'C' THEN 1 ELSE 0 END) AS C_Process
		FROM process_student a
		INNER JOIN studentInfo b ON a.student_id = b.studentid
		INNER JOIN process c ON a.process_id = c.process_id
		WHERE a.process_id IN (2, 5) AND process_student_status <> 'X'
		GROUP BY NienKhoa, HeDaoTaoID, HeDaoTao, process_description;

END