--- [spAPI_SDH_ThongKe_DeTai_DaHoanThanh] 0, 9
CREATE PROC [dbo].[spAPI_SDH_ThongKe_DeTai_DaHoanThanh] 
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
	-- Tạo bảng tạm
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
		Thesis_Name NVARCHAR(500),
		Thesises_Prof1 NVARCHAR(500),
		Thesises_Prof2 NVARCHAR(500),
		ThesisConfirmNo NVARCHAR(100),
		FileThesisConfirm NVARCHAR(500),
		ThoiGianBaoVe VARCHAR(10),
		SoQDLapHoiDong NVARCHAR(50),
		HeSoHuongDan FLOAT
	);
	-- Chèn dữ liệu vào bảng tạm
	INSERT INTO @TempTable (
		Student_ID, Ho_SV, Ten_SV, Ngay_Sinh, Noi_Sinh, Lop_ID, Nganh_ID, Ten_Nganh, Nien_Khoa, 
		Thesis_Name, Thesises_Prof1, Thesises_Prof2, ThesisConfirmNo, FileThesisConfirm, ThoiGianBaoVe, SoQDLapHoiDong, HeSoHuongDan
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
	 , ThesisName AS Thesis_Name
	 , ThesisesProf1 AS Thesises_Prof1
	 , ThesisesProf2 AS Thesises_Prof2
	 , ThesisConfirmNo AS ThesisConfirmNo
	 , FileThesisConfirm AS FileThesisConfirm
	 , hd.ThoiGianBaoVe
	 , de.Decision_SoQD
	 --, MarkAVG AS MarkAVG_STATUS
	  , CASE WHEN ISNULL(ThesisesProf1,'') <>'' AND ISNULL(ThesisesProf2,'') <> '' THEN 0.5
		 ELSE 1 END
	FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
							AND a.task_detail_id = b.task_detail_id AND b.fieldname ='ThesisConfirm'
					   INNER JOIN flow c ON a.flow_id = c.flow_id   AND c.use_yn = 1 and a.Flow_Detail_Status = 'C'
					   INNER JOIN StudentInfo d ON c.student_id = d.StudentID 
					   LEFT JOIN HoiDong hd ON hd.StudentID = d.StudentID
					   LEFT JOIN Decision de ON hd.HoiDongID = de.HoiDong_ID
					   --INNER JOIN StudenList e ON e.student_id = c.Student_ID 
					   LEFT JOIN (SELECT c.Student_id
								, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
								, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
								, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
								, MAX(CASE WHEN fieldname='ThesisConfirmNo' THEN text_content ELSE '' END) ThesisConfirmNo
								, MAX(CASE WHEN fieldname='ThesisConfirm' THEN File_URL ELSE '' END) FileThesisConfirm
								, MAX(CASE WHEN fieldname='MarkAVG' THEN a.Flow_Detail_Status ELSE '' END) MarkAVG					
									FROM flow_detail a INNER JOIN task_detail b ON a.task_id = b.task_id 
																		AND a.task_detail_id = b.task_detail_id 
																		AND b.fieldname IN('ThesisName'
																						,'ThesisesProf1'
																						,'ThesisesProf2'
																						,'ThesisConfirmNo'
																						, 'ThesisConfirm'
																						,'MarkAVG') 
													   INNER JOIN flow c on a.flow_id = c.flow_id  and c.use_yn = 1
													  -- INNER JOIN StudenList e ON e.student_id = c.Student_ID
									WHERE   a.use_yn = 1
									GROUP BY c.student_id
								   ) f ON c.student_id = f.student_id
	where a.use_yn = 1 AND F.MarkAVG = 'C'
	AND ( D.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	order by Nganh_ID, Nien_Khoa


	-- table 1 
	SELECT DISTINCT T.*, d.Decision_NgayQD, D.Decision_ThangQD, D.Decision_NamQD
	FROM  @TempTable T LEFT JOIN Decision D ON T.FileThesisConfirm = D.DecisionFile_Url AND D.Decision_Status = 3 --AND Decision_Type ='DGLVCH'


	--table 2
	-- Thống kê số lượng đề tài theo tên giáo viên
	SELECT 
		Prof_Name, 
		Nganh_ID,
		sum(HeSoHuongDan) AS NumberOfTopics
	FROM (
		SELECT Thesises_Prof1 AS Prof_Name, Nganh_ID, HeSoHuongDan
		FROM @TempTable
		WHERE Thesises_Prof1 IS NOT NULL AND Thesises_Prof1 <> ''
    
		UNION ALL
    
		SELECT Thesises_Prof2 AS Prof_Name, Nganh_ID, HeSoHuongDan
		FROM @TempTable
		WHERE Thesises_Prof2 IS NOT NULL AND Thesises_Prof2 <> ''
	) AS CombinedProfessors
	GROUP BY Prof_Name, Nganh_ID
	ORDER BY NumberOfTopics DESC;
				
END




--select COUNT(*), STUDENT_ID from Process_Student GROUP BY STUDENT_ID HAVING COUNT(*) > 1

--SELECT * FROM Process_Student WHERE Student_ID =921000065
