--- [spAPI_SDH_ThongKe_DeTai_ChuaNopDeCuong] 0, 9
CREATE PROC [dbo].[spAPI_SDH_ThongKe_DeTai_ChuaNopDeCuong] 
@Nganh_ID INT,
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
	-- Tạo bảng tạm lấy ra những sinh viên đã Complete bước 2
	DECLARE @TempTable AS TABLE (
		Student_ID VARCHAR(9),
		Ho_SV NVARCHAR(100),
		Ten_SV NVARCHAR(100),
		Ngay_Sinh VARCHAR(10),
		Noi_Sinh NVARCHAR(100),
		Lop_ID VARCHAR(10),
		Nganh_ID INT,
		Ten_Nganh NVARCHAR(100),
		Nien_Khoa VARCHAR(10),
		ThesisNameSuggest NVARCHAR(500),
		Thesises_Prof1 NVARCHAR(500),
		Thesises_Prof2 NVARCHAR(500)
	);
	-- Chèn dữ liệu vào bảng tạm
	INSERT INTO @TempTable (
		Student_ID, Ho_SV, Ten_SV, Ngay_Sinh, Noi_Sinh, Lop_ID, Nganh_ID, Ten_Nganh, Nien_Khoa, 
		ThesisNameSuggest, Thesises_Prof1, Thesises_Prof2
	)
	 SELECT DISTINCT d.StudentID AS Student_ID
	 , HoSV AS Ho_SV
	 , TenSV AS Ten_SV
	 , NgaySinh AS Ngay_Sinh
	 , NoiSinh AS Noi_Sinh
	 , LopID AS Lop_ID
	 , NganhID AS Nganh_ID
	 , TenNganh AS Ten_Nganh
	 , NienKhoa AS Nien_Khoa
	 , ThesisNameSuggest AS ThesisNameSuggest
	 , ThesisesProf1 AS Thesises_Prof1
	 , ThesisesProf2 AS Thesises_Prof2
	FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
							AND a.task_detail_id = b.task_detail_id AND b.fieldname ='ThesisesProf1'
					   INNER JOIN flow c ON a.flow_id = c.flow_id   AND c.use_yn = 1  and a.Flow_Detail_Status IN ('C')
					   INNER JOIN StudentInfo d ON c.student_id = d.StudentID 
					   LEFT JOIN (SELECT c.Student_id
								, MAX(CASE WHEN fieldname='ThesisNameSuggest' THEN text_content ELSE ' ' END) ThesisNameSuggest
								, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
								, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2				
									FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
																		AND a.task_detail_id = b.task_detail_id 
																		AND b.fieldname IN('ThesisNameSuggest'
																						,'ThesisesProf1'
																						,'ThesisesProf2') 
													   INNER JOIN flow c on a.flow_id = c.flow_id  and c.use_yn = 1
									WHERE   a.use_yn = 1
									GROUP BY c.student_id
								   ) f ON c.student_id = f.student_id
	where a.use_yn = 1 
	AND ( D.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	order by Nganh_ID, Nien_Khoa



	 SELECT DISTINCT d.StudentID AS Student_ID
	 , d.HoSV AS Ho_SV
	 , d.TenSV AS Ten_SV
	 , d.NgaySinh AS Ngay_Sinh
	 , d.NoiSinh AS Noi_Sinh
	 , d.LopID AS Lop_ID
	 , d.NganhID AS Nganh_ID
	 , d.TenNganh AS Ten_Nganh
	 , d.NienKhoa AS Nien_Khoa
	 , ThesisNameSuggest AS ThesisNameSuggest
	 , ThesisName AS Thesis_Name
	 , ThesisesProf1 AS Thesises_Prof1
	 , ThesisesProf2 AS Thesises_Prof2
	 , ThesisConfirmNo AS ThesisConfirmNo
	 , FileThesisConfirm AS FileThesisConfirm
	 , fileDeCuong as fileDeCuong
	 , a.Flow_Detail_Status
     , a.Updated_At as NgayDangKy
	FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
							AND a.task_detail_id = b.task_detail_id AND b.fieldname ='fileDeCuong'
					   INNER JOIN flow c ON a.flow_id = c.flow_id   AND c.use_yn = 1  and a.Flow_Detail_Status IN ('W','P')
					   INNER JOIN StudentInfo d ON c.student_id = d.StudentID 
					   INNER JOIN @TempTable T ON T.Student_ID = D.StudentID
					   LEFT JOIN (SELECT c.Student_id
								, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
								, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
								, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
								, MAX(CASE WHEN fieldname='ThesisConfirmNo' THEN text_content ELSE '' END) ThesisConfirmNo
								, MAX(CASE WHEN fieldname='ThesisConfirm' THEN File_URL ELSE '' END) FileThesisConfirm
								, MAX(CASE WHEN fieldname='fileDeCuong' THEN File_URL ELSE '' END) fileDeCuong					
									FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
																		AND a.task_detail_id = b.task_detail_id 
																		AND b.fieldname IN('ThesisName'
																						,'ThesisesProf1'
																						,'ThesisesProf2'
																						,'ThesisConfirmNo'
																						, 'ThesisConfirm'
																						,'fileDeCuong') 
													   INNER JOIN flow c on a.flow_id = c.flow_id  and c.use_yn = 1
									WHERE   a.use_yn = 1
									GROUP BY c.student_id
								   ) f ON c.student_id = f.student_id
	INNER JOIN StudentInfo si ON si.StudentID = d.StudentID AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	where a.use_yn = 1 
	AND ( D.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	order by Nganh_ID, Nien_Khoa


END


