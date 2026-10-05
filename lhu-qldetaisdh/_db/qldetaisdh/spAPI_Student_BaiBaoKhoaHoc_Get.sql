CREATE PROC [dbo].[spAPI_Student_BaiBaoKhoaHoc_Get]
	@Nganh_ID INT,
	@BaiBaoStatus INT -- 0. Tất cả, 1. Học viên đã đăng bài, 2. Học viên chưa đăng bài
AS
BEGIN
	-- Tạo bảng tạm
	DECLARE @TempTable AS TABLE
	(
		Student_ID VARCHAR(9),
		Ho_SV NVARCHAR(100),
		Ten_SV NVARCHAR(100),
		Lop_ID VARCHAR(10),
		Nganh_ID INT,
		Ten_Nganh NVARCHAR(100),
		Nien_Khoa VARCHAR(10),
		Thesis_Name NVARCHAR(500),
		Thesises_Prof1 NVARCHAR(500),
		Thesises_Prof2 NVARCHAR(500),
		FileBaiBaoKhoaHocID VARCHAR(50),
		FileBaiBaoKhoaHocName NVARCHAR(255),
		TenBaiBao NVARCHAR(300),
		TenTapChi_HoiThao NVARCHAR(300),
		NamXuatBan NVARCHAR(25),
		ViTriTacGia NVARCHAR(255),
		DiemHoiDongGS NVARCHAR(255)
	);

	INSERT @TempTable
	(
		Student_ID,
		Ho_SV,
		Ten_SV,
		Lop_ID,
		Nganh_ID,
		Ten_Nganh,
		Nien_Khoa,
		Thesis_Name,
		Thesises_Prof1,
		Thesises_Prof2,
		FileBaiBaoKhoaHocID,
		FileBaiBaoKhoaHocName,
		TenBaiBao,
		TenTapChi_HoiThao,
		NamXuatBan,
		ViTriTacGia,
		DiemHoiDongGS
	)
	SELECT DISTINCT si.StudentID AS Student_ID
		 , HoSV AS Ho_SV
		 , TenSV AS Ten_SV
		 , LopID AS Lop_ID
		 , NganhID AS Nganh_ID
		 , TenNganh AS Ten_Nganh
		 , NienKhoa AS Nien_Khoa
		 , ThesisName AS Thesis_Name
		 , ThesisesProf1 AS Thesises_Prof1
		 , ThesisesProf2 AS Thesises_Prof2
		 , File_ID
		 , File_Name
		 , TenBaiBao
		 , TenTapChi_HoiThao
		 , NamXuatBan
		 , ViTriTacGia
		 , DiemHoiDongGS
	FROM Flow_Detail fd
	INNER JOIN Task_Detail tb ON fd.Task_ID = tb.Task_ID
		AND fd.Task_Detail_ID = tb.Task_Detail_ID
		AND tb.FieldName = 'fileBaiBaoKhoaHoc'
	INNER JOIN Flow fl ON fd.Flow_ID = fl.Flow_ID 
		AND fl.use_yn = 1 
		AND fd.Flow_Detail_Status = 'C'
	INNER JOIN StudentInfo si ON si.StudentID = fl.Student_ID
	LEFT JOIN (SELECT c.Student_id
			, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
			, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
			, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
			, MAX(CASE WHEN fieldname='fileBaiBaoKhoaHoc' THEN text_content ELSE '' END) FileBaiBaoKhoaHoc	
			, MAX(CASE WHEN fieldname='tenBaiBao' THEN text_content ELSE '' END) TenBaiBao
			, MAX(CASE WHEN fieldname='tenTapChiHoiThao' THEN text_content ELSE '' END) TenTapChi_HoiThao
			, MAX(CASE WHEN fieldname='viTriTacGia' THEN text_content ELSE '' END) ViTriTacGia
			, MAX(CASE WHEN fieldname='diemHoiDongBaiBao' THEN text_content ELSE '' END) DiemHoiDongGS
			, MAX(CASE WHEN fieldname='namXuatBan' THEN text_content ELSE '' END) NamXuatBan
		FROM Flow_Detail a 
		INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID 
			AND a.Task_Detail_ID = b.Task_Detail_ID 
			AND b.FieldName IN('ThesisName'
								,'ThesisesProf1'
								,'ThesisesProf2'
								,'fileBaiBaoKhoaHoc'
								,'tenBaiBao'
								,'tenTapChiHoiThao'
								,'namXuatBan'
								,'viTriTacGia'
								,'diemHoiDongBaiBao') 
		 INNER JOIN Flow c on a.Flow_ID = c.Flow_ID  and c.use_yn = 1
		-- INNER JOIN StudenList e ON e.student_id = c.Student_ID
			WHERE   a.use_yn = 1
			GROUP BY c.Student_ID
		) f ON fl.Student_ID = f.Student_ID
	where fd.use_yn = 1
	AND ( si.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	--order by Nganh_ID, Nien_Khoa

	SELECT DISTINCT *
	FROM  @TempTable tb
	INNER JOIN StudentInfo si ON si.StudentID = tb.Student_ID AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	WHERE 
		(@BaiBaoStatus = 0)
		OR (@BaiBaoStatus = 1 AND FileBaiBaoKhoaHocID IS NOT NULL AND FileBaiBaoKhoaHocID <> '')
		OR (@BaiBaoStatus = 2 AND (FileBaiBaoKhoaHocID IS NULL OR FileBaiBaoKhoaHocID = ''))
END