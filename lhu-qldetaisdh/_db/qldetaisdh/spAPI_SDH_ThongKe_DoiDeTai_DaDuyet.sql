--- [spAPI_SDH_ThongKe_DoiDeTai_DaDuyet] 0, 9
CREATE PROC [dbo].[spAPI_SDH_ThongKe_DoiDeTai_DaDuyet] 
@Nganh_ID INT,
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	DECLARE @DoiDeTai_NC_Process_ID INT = 2
	DECLARE @DoiDeTai_UD_Process_ID INT = 5
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
		Thesis_Name_New NVARCHAR(500),
		Thesises_Prof1_New NVARCHAR(500),
		Thesises_Prof2_New NVARCHAR(500)
	)
	-- Chèn dữ liệu vào bảng tạm
	INSERT INTO @TempTable (
		Student_ID, Ho_SV, Ten_SV, Ngay_Sinh, Noi_Sinh, Lop_ID, Nganh_ID, Ten_Nganh, Nien_Khoa, 
		Thesis_Name_New, Thesises_Prof1_New, Thesises_Prof2_New
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
	 , ThesisNameNew AS Thesis_Name_New
	 , ThesisesProf1New AS Thesises_Prof1_New
	 , ThesisesProf2New AS Thesises_Prof2_New
	FROM flow_detail a INNER JOIN task_detail b ON a.task_detail_id = b.task_detail_id 
	--AND b.fieldname ='QuyetDinhDoiDeTai' 
				
					   INNER JOIN flow c ON a.flow_id = c.flow_id  and c.Task_ID in (13,37) 
					   --and c.Flow_Status = 'C'
					   INNER JOIN StudentInfo d ON c.student_id = d.StudentID AND (d.IsXuLyHocVu = 0 OR d.IsXuLyHocVu IS NULL)
					   LEFT JOIN (SELECT c.Student_id, c.Flow_ID, c.Flow_Status
								, MAX(CASE WHEN fieldname='ThesisNameNew' THEN text_content ELSE ' ' END) ThesisNameNew
								, MAX(CASE WHEN fieldname='ThesisesProf1New' THEN text_content ELSE N'' END) ThesisesProf1New
								, MAX(CASE WHEN fieldname='ThesisesProf2New' THEN text_content ELSE N'' END) ThesisesProf2New				
									FROM flow_detail a INNER JOIN task_detail b ON a.task_detail_id = b.task_detail_id 
																		AND b.fieldname IN('ThesisNameNew'
																						,'ThesisesProf1New'
																						,'ThesisesProf2New') 
													   INNER JOIN flow c on a.flow_id = c.flow_id  and c.use_yn = 1
													   
									WHERE   a.use_yn = 1
									GROUP BY c.student_id,  c.Flow_ID, c.Flow_Status
								   ) f ON c.student_id = f.student_id
	where a.use_yn = 1
	-- AND a.Flow_Detail_Status <> 'C'
	AND C.Process_ID IN (2,5)
	AND ( D.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	order by Nganh_ID, Nien_Khoa;

	--Lấy row cuối cùng trong trường hợp đổi đề tài lần 2 và @TempTable select được 2 rows dữ liệu trở lên
	WITH FullData AS (
			SELECT 
				d.StudentID AS Student_ID,
				d.HoSV AS Ho_SV,
				d.TenSV AS Ten_SV,
				d.NgaySinh AS Ngay_Sinh,
				d.NoiSinh AS Noi_Sinh,
				d.LopID AS Lop_ID,
				d.NganhID AS Nganh_ID,
				d.TenNganh AS Ten_Nganh,
				d.NienKhoa AS Nien_Khoa,
				a.Text_Content AS Thesis_Name_Old,
				f.Thesis_Name_New,
				f.Thesises_Prof1_New,
				f.Thesises_Prof2_New,
				c.Process_Student_ID,
				-- Xếp hạng ưu tiên: càng thấp càng ưu tiên
				ROW_NUMBER() OVER (
					PARTITION BY d.StudentID
					ORDER BY
						-- Ưu tiên dòng có cả hai thesis
						CASE 
							WHEN f.Thesis_Name_New IS NOT NULL AND a.Text_Content IS NOT NULL THEN 1
							WHEN f.Thesis_Name_New IS NOT NULL THEN 2
							WHEN a.Text_Content IS NOT NULL THEN 3
							ELSE 4
						END,
						c.Process_Student_ID DESC -- Nếu bằng nhau, lấy Process mới nhất
				) AS rn
			FROM flow_detail a
			JOIN task_detail b ON a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName'
			JOIN flow c ON a.flow_id = c.flow_id
			JOIN StudentInfo d ON c.student_id = d.StudentID
			JOIN Process_Student p ON p.Process_Stu_ID = c.Process_Student_ID
				AND p.Process_ID IN (1,4) 
				--AND p.Process_Student_Status in('P', 'X')
			JOIN @TempTable f ON c.student_id = f.student_id
			WHERE 
				--a.use_yn = 0 AND 
			  (d.NganhID = @Nganh_ID OR @Nganh_ID = 0)
			  AND (ISNULL(f.Thesis_Name_New,'') <>'' OR ISNULL(f.Thesises_Prof1_New,'') <>'' OR ISNULL(f.Thesises_Prof2_New,'') <>'')
		)

	SELECT DISTINCT
		f.Student_ID, 
		f.Ho_SV, 
		f.Ten_SV, 
		f.Ngay_Sinh, 
		f.Noi_Sinh, 
		f.Lop_ID, 
		f.Nganh_ID, 
		f.Ten_Nganh, 
		f.Nien_Khoa, 
		f.Thesis_Name_Old, 
		f.Thesis_Name_New, 
		f.Thesises_Prof1_New, 
		f.Thesises_Prof2_New, 
		gv1.CoQuanCongTac AS CoQuanCongTacGV1,
		gv2.CoQuanCongTac AS CoQuanCongTacGV2,
		f.Process_Student_ID
	FROM FullData f
	INNER JOIN Process_Student p ON p.Student_ID = f.Student_ID
		-- Lấy tất cả/Filter trạng thái
		AND p.Process_Student_Status IN ('W', 'P')
		AND p.Process_ID IN(@DoiDeTai_NC_Process_ID, @DoiDeTai_UD_Process_ID)
	LEFT JOIN GiangVien gv1
		ON f.Thesises_Prof1_New = 
		   CONCAT(gv1.HocViHocHam, '. ', gv1.HoTenGiangVien)
	LEFT JOIN GiangVien gv2
	    ON f.Thesises_Prof2_New = 
	       CONCAT(gv2.HocViHocHam, '. ', gv2.HoTenGiangVien)
	WHERE rn = 1
	ORDER BY Nganh_ID, Nien_Khoa, Student_ID
	--lấy ra những đứa đổi đề tài
END

---------Backup code
	--WITH FullData AS (
	--		SELECT 
	--			d.StudentID AS Student_ID,
	--			d.HoSV AS Ho_SV,
	--			d.TenSV AS Ten_SV,
	--			d.NgaySinh AS Ngay_Sinh,
	--			d.NoiSinh AS Noi_Sinh,
	--			d.LopID AS Lop_ID,
	--			d.NganhID AS Nganh_ID,
	--			d.TenNganh AS Ten_Nganh,
	--			d.NienKhoa AS Nien_Khoa,
	--			a.Text_Content AS Thesis_Name_Old,
	--			f.Thesis_Name_New,
	--			f.Thesises_Prof1_New,
	--			f.Thesises_Prof2_New,
	--			c.Process_Student_ID,
	--			--a.use_yn,
	--			--p.Process_Student_Status,
	--			--p.Process_ID,
	--			-- Xếp hạng ưu tiên: càng thấp càng ưu tiên
	--			ROW_NUMBER() OVER (
	--				PARTITION BY d.StudentID
	--				ORDER BY
	--					-- Ưu tiên dòng có cả hai thesis
	--					CASE 
	--						WHEN f.Thesis_Name_New IS NOT NULL AND a.Text_Content IS NOT NULL THEN 1
	--						WHEN f.Thesis_Name_New IS NOT NULL THEN 2
	--						WHEN a.Text_Content IS NOT NULL THEN 3
	--						ELSE 4
	--					END,
	--					c.Process_Student_ID DESC -- Nếu bằng nhau, lấy Process mới nhất
	--			) AS rn
	--		FROM flow_detail a
	--		JOIN task_detail b ON a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName'
	--		JOIN flow c ON a.flow_id = c.flow_id
	--		JOIN StudentInfo d ON c.student_id = d.StudentID
	--		JOIN Process_Student p ON p.Process_Stu_ID = c.Process_Student_ID
	--			AND p.Process_ID IN (1,4) 
	--			--AND p.Process_Student_Status in('P', 'X')
	--		JOIN @TempTable f ON c.student_id = f.student_id
	--		WHERE 
	--			--a.use_yn = 0 AND 
	--		  (d.NganhID = @Nganh_ID OR @Nganh_ID = 0)
	--		  AND (ISNULL(f.Thesis_Name_New,'') <>'' OR ISNULL(f.Thesises_Prof1_New,'') <>'' OR ISNULL(f.Thesises_Prof2_New,'') <>'')
	--	)

