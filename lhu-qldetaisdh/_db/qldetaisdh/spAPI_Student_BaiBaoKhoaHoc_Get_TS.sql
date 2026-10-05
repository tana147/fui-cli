CREATE PROC [dbo].[spAPI_Student_BaiBaoKhoaHoc_Get_TS]
@Nganh_ID INT,
@BaiBaoStatus INT -- 0: Tất cả, 1: Đã nộp bài báo/minh chứng, 2: Chưa nộp
AS
BEGIN
	SELECT DISTINCT
		si.StudentID AS Student_ID,
		si.HoSV AS Ho_SV,
		si.TenSV AS Ten_SV,
		si.LopID AS Lop_ID,
		si.NganhID AS Nganh_ID,
		si.TenNganh AS Ten_Nganh,
		si.NienKhoa AS Nien_Khoa,
		f.ThesisName AS Thesis_Name,
		f.ThesisesProf1 AS Thesises_Prof1,
		f.ThesisesProf2 AS Thesises_Prof2,
		fd.File_ID AS FileBaiBaoKhoaHocID,
		fd.File_Name AS FileBaiBaoKhoaHocName,
		ISNULL(fd.Text_Content, fd.File_Name) AS TenBaiBao,
		'' AS TenTapChi_HoiThao,
		'' AS NamXuatBan,
		'' AS ViTriTacGia,
		'' AS DiemHoiDongGS
	FROM StudentInfo si
	LEFT JOIN Flow fl ON fl.Student_ID = si.StudentID AND fl.Task_ID = 40 AND fl.use_yn = 1
	LEFT JOIN Flow_Detail fd ON fd.Flow_ID = fl.Flow_ID AND fd.use_yn = 1 
		AND fd.Task_Detail_ID IN (SELECT Task_Detail_ID FROM Task_Detail WHERE FieldName = 'MinhChungBaiBao' AND Task_ID = 40)
	LEFT JOIN (
		SELECT 
			c.Student_id,
			MAX(CASE WHEN b.fieldname='ThesisName' THEN a.text_content ELSE '' END) AS ThesisName,
			MAX(CASE WHEN b.fieldname='ThesisesProf1' THEN a.text_content ELSE '' END) AS ThesisesProf1,
			MAX(CASE WHEN b.fieldname='ThesisesProf2' THEN a.text_content ELSE '' END) AS ThesisesProf2
		FROM Flow_Detail a 
		INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID AND a.Task_Detail_ID = b.Task_Detail_ID 
			AND b.FieldName IN ('ThesisName', 'ThesisesProf1', 'ThesisesProf2')
		INNER JOIN Flow c ON a.Flow_ID = c.Flow_ID AND c.use_yn = 1
		WHERE a.use_yn = 1
		GROUP BY c.Student_ID
	) f ON f.Student_ID = si.StudentID
	WHERE (si.HeDaoTao = 'Phd' OR SUBSTRING(si.LopID, 3, 1) = 'N' OR si.NganhID IN ('43', '44'))
	  AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	  AND (@Nganh_ID = 0 OR si.NganhID = @Nganh_ID)
	  AND (
	      @BaiBaoStatus = 0
	      OR (@BaiBaoStatus = 1 AND fd.File_ID IS NOT NULL AND fd.File_ID <> '')
	      OR (@BaiBaoStatus = 2 AND (fd.File_ID IS NULL OR fd.File_ID = ''))
	  )
	ORDER BY si.StudentID
END