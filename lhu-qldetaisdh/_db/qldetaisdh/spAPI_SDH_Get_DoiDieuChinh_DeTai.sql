
 -- [dbo].[spAPI_Get_FlowDetail] 6932
CREATE PROC [dbo].[spAPI_SDH_Get_DoiDieuChinh_DeTai]
@Nganh_ID INT
AS
BEGIN
	DECLARE @Process_ID_NC INT = 1
	DECLARE @Process_ID_UD INT = 4
	DECLARE @Task_ID_Diem_BaoVe_NC INT = 6
	DECLARE @Task_ID_Diem_BaoVe_UD INT = 24
	DECLARE @Task_Detail_ID_DiemTB_NC INT = 36
	DECLARE @Task_Detail_ID_DiemTB_UD INT = 88;
	
	WITH Ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Student_ID ORDER BY Created_At DESC) AS rn,
		   COUNT(Student_ID) OVER(PARTITION BY Student_ID) AS SoLanDoiDieuChinh
    FROM Process_Student
    WHERE Process_Student_Status = 'X'
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

    fd.Text_Content AS DiemTB,
	
    -- 1: Đổi đề tài, 2: Điều chỉnh đề tài
    CASE
        WHEN fd.Text_Content IS NOT NULL
             AND LTRIM(RTRIM(fd.Text_Content)) <> '' AND fd.Text_Content IS NOT NULL
        THEN 2
        ELSE 1
    END AS IsDoiDeTaiOrDieuChinh

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

OUTER APPLY
(
    SELECT TOP 1
        ps.Process_Stu_ID
    FROM Process_Student ps
    WHERE ps.Student_ID = r.Student_ID
      AND ps.Process_Student_Status = 'X'
      AND ps.Process_ID IN (@Process_ID_NC,@Process_ID_UD)
    ORDER BY ps.Updated_At DESC
) psLatest

OUTER APPLY
(
    SELECT TOP 1
        fd.Text_Content
    FROM Flow f
    INNER JOIN Flow_Detail fd
        ON fd.Flow_ID = f.Flow_ID
    WHERE f.Process_Student_ID = psLatest.Process_Stu_ID
      AND f.Task_ID IN (@Task_ID_Diem_BaoVe_NC,@Task_ID_Diem_BaoVe_UD)
      AND fd.Task_Detail_ID IN (@Task_Detail_ID_DiemTB_NC,@Task_Detail_ID_DiemTB_UD)
      AND fd.Use_YN = 0
) fd

WHERE r.rn = 1
  AND (si.NganhID = @Nganh_ID OR @Nganh_ID = 0)

ORDER BY
    si.NganhID,
    si.NienKhoa
	
--	SELECT 
--		   r.Student_ID,
--		   r.SoLanDoiDieuChinh,
--		   si.HoSV,
--		   si.TenSV,
--		   si.NienKhoa AS Nien_Khoa,
--		   si.TenNganh,
--		   si.LopID,
--		   si.NganhID,
--		   d.Decision_ID,
--		   d.DecisionFile_ID,
--		   d.DecisionFile_Name,
--		   d.DecisionFile_Url,
--		   d.Decision_SoQD,
--		   d.Decision_NgayQD,
--		   d.Decision_ThangQD,
--		   d.Decision_NamQD,
--		   r.Process_ID,
--		   td.NewThesisName,
--		   td.ThesisesProf1,
--		   td.ThesisesProf2
--	FROM Ranked r
--	INNER JOIN StudentInfo si ON si.StudentID = r.Student_ID AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
--	LEFT JOIN ThesisData td ON td.Student_id = r.Student_ID
--	LEFT JOIN Decision_Change_Thesis dc ON r.Student_ID = dc.StudentID AND dc.Use_YN = 1
--	LEFT JOIN Decision d ON d.Decision_ID = dc.Decision_ID
--	WHERE r.rn = 1
--	  AND (si.NganhID = @Nganh_ID OR @Nganh_ID = 0)
--	 ORDER BY si.NganhID, si.NienKhoa
END