CREATE PROC [dbo].[spAPI_SDH_Get_DoiDieuChinh_DeTai_TS]
@Nganh_ID INT
AS
BEGIN
	DECLARE @Process_ID_TS INT = 6;
	DECLARE @Process_ID_DoiDeTai_TS INT = 7;
	
	WITH Ranked AS (
		SELECT *,
			   ROW_NUMBER() OVER (PARTITION BY Student_ID ORDER BY Created_At DESC) AS rn,
			   COUNT(Student_ID) OVER(PARTITION BY Student_ID) AS SoLanDoiDieuChinh
		FROM Process_Student
		WHERE Process_ID = @Process_ID_DoiDeTai_TS
	),
	ThesisData AS (
		SELECT 
			c.Student_id,
			MAX(CASE WHEN b.fieldname = 'ThesisName' THEN a.text_content ELSE NULL END) AS NewThesisName,
			MAX(CASE WHEN b.fieldname = 'ThesisesProf1' THEN a.text_content ELSE NULL END) AS ThesisesProf1,
			MAX(CASE WHEN b.fieldname = 'ThesisesProf2' THEN a.text_content ELSE NULL END) AS ThesisesProf2
		FROM flow_detail a
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		WHERE a.use_yn = 1
		  AND b.fieldname IN ('ThesisName', 'ThesisesProf1', 'ThesisesProf2')
		GROUP BY c.Student_id
	)
	SELECT 
		r.Student_ID,
		r.SoLanDoiDieuChinh,
		si.HoSV,
		si.TenSV,
		si.NienKhoa AS Nien_Khoa,
		si.TenNganh,
		si.LopID,
		si.NganhID,
		d.Decision_ID,
		d.DecisionFile_ID,
		d.DecisionFile_Name,
		d.DecisionFile_Url,
		d.Decision_SoQD,
		d.Decision_NgayQD,
		d.Decision_ThangQD,
		d.Decision_NamQD,
		r.Process_ID,
		td.NewThesisName,
		td.ThesisesProf1,
		td.ThesisesProf2,
		NULL AS DiemTB,
		1 AS IsDoiDeTaiOrDieuChinh
	FROM Ranked r
	INNER JOIN StudentInfo si
		ON si.StudentID = r.Student_ID
		AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	LEFT JOIN ThesisData td
		ON td.Student_ID = r.Student_ID
	LEFT JOIN Decision_Change_Thesis dc
		ON dc.StudentID = r.Student_ID
		AND dc.Use_YN = 1
	LEFT JOIN Decision d
		ON d.Decision_ID = dc.Decision_ID
	WHERE r.rn = 1
	  AND (@Nganh_ID = 0 OR si.NganhID = @Nganh_ID)
END