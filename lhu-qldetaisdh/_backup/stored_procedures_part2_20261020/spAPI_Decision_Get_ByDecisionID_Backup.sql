-- [dbo].[spAPI_Decision_Get_ByDecisionID_Backup] 2651, 9 
CREATE PROC [dbo].[spAPI_Decision_Get_ByDecisionID_Backup]   
@Decision_ID INT,
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

	DECLARE @Decision_SoQD NVARCHAR(100)
	DECLARE @Decision_NamQD VARCHAR(10)
	DECLARE @Decision_NganhID NVARCHAR(200)
	DECLARE @Decission_Type NVARCHAR(200)
	SELECT @Decision_SoQD = LTRIM(RTRIM(D.Decision_SoQD)), @Decision_NganhID = D.Decision_NganhID, @Decission_Type = D.Decision_Type 
	FROM Decision D 
	WHERE D.Decision_ID = @Decision_ID;

	DECLARE @tb AS TABLE(Student_ID CHAR(9)
					,Ho_SV NVARCHAR(200)
					,Ten_SV NVARCHAR(50)
					,Ngay_Sinh VARCHAR(10)
					,Noi_Sinh NVARCHAR(200)
					,Lop_ID VARCHAR(10)
					,Nganh_ID VARCHAR(10)
					,Ten_Nganh NVARCHAR(200)
					,Nien_Khoa VARCHAR(10)
					,Thesis_Name NVARCHAR(500)
					,Thesises_Prof1 NVARCHAR(500)
					,Thesises_Prof2 NVARCHAR(500)
					,ThesisesProf_Email1 NVARCHAR(500)
					,ThesisesProf_Email2 NVARCHAR(500)
					,ThesisesProf_Phone1 NVARCHAR(500)
					,ThesisesProf_Phone2 NVARCHAR(500)
					,ThesisesProf_Uni1 NVARCHAR(500)
					,ThesisesProf_Uni2 NVARCHAR(500));

	-- 1. Nếu là quyết định Hội đồng (sinh từ trang council hoặc có trong bảng HoiDong)
	IF EXISTS (SELECT 1 FROM HoiDong WHERE Decision_ID = @Decision_ID AND Is_Xoa = 0)
	BEGIN
		INSERT INTO @tb(Student_ID 
						,Ho_SV
						,Ten_SV
						,Ngay_Sinh
						,Noi_Sinh
						,Lop_ID
						,Nganh_ID
						,Ten_Nganh
						,Nien_Khoa
						,Thesis_Name
						,Thesises_Prof1
						,Thesises_Prof2
						)
		SELECT d.StudentID AS Student_ID
		, d.HoSV AS Ho_SV
		, d.TenSV AS Ten_SV
		, d.NgaySinh AS Ngay_Sinh
		, d.NoiSinh AS Noi_Sinh
		, d.LopID AS Lop_ID
		, d.NganhID AS Nganh_ID
		, d.TenNganh AS Ten_Nganh
		, d.NienKhoa AS Nien_Khoa
		, COALESCE(NULLIF(LTRIM(RTRIM(hd.DeTai)), ''), f.ThesisName, ' ') AS Thesis_Name
		, ISNULL(f.ThesisesProf1, N'') AS Thesises_Prof1
		, ISNULL(f.ThesisesProf2, N'') AS Thesises_Prof2
		FROM HoiDong hd
		INNER JOIN StudentInfo d ON hd.StudentID = d.StudentID
		OUTER APPLY (
			SELECT 
				MAX(CASE WHEN b.fieldname='ThesisName' THEN a.text_content ELSE ' ' END) ThesisName,
				MAX(CASE WHEN b.fieldname='ThesisesProf1' THEN a.text_content ELSE N'' END) ThesisesProf1,
				MAX(CASE WHEN b.fieldname='ThesisesProf2' THEN a.text_content ELSE N'' END) ThesisesProf2
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id 
				AND b.fieldname IN('ThesisName', 'ThesisesProf1', 'ThesisesProf2') 
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE a.use_yn = 1 AND c.Student_ID = hd.StudentID
		) f
		WHERE hd.Decision_ID = @Decision_ID AND hd.Is_Xoa = 0;
	END
	ELSE
	BEGIN
		-- 2. Nếu là quyết định Giao đề tài (khớp số QĐ trong Flow_Detail.ThesisConfirmNo, xử lý lệch khoảng trắng)
		WITH StudenList AS (
			SELECT C.Student_ID 
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id 
										AND a.task_detail_id = b.task_detail_id 
										AND b.fieldname ='ThesisConfirmNo'
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			WHERE b.FieldName = 'ThesisConfirmNo' 
				AND LTRIM(RTRIM(a.Text_Content)) = @Decision_SoQD
		)
		INSERT INTO @tb(Student_ID 
						,Ho_SV
						,Ten_SV
						,Ngay_Sinh
						,Noi_Sinh
						,Lop_ID
						,Nganh_ID
						,Ten_Nganh
						,Nien_Khoa
						,Thesis_Name
						,Thesises_Prof1
						,Thesises_Prof2
						)
		SELECT d.StudentID AS Student_ID
		, HoSV AS Ho_SV
		, TenSV AS Ten_SV
		, NgaySinh AS Ngay_Sinh
		, NoiSinh AS Noi_Sinh
		, LopID AS Lop_ID
		, d.NganhID AS Nganh_ID
		, TenNganh AS Ten_Nganh
		, NienKhoa AS Nien_Khoa
		, f.ThesisName AS Thesis_Name
		, f.ThesisesProf1 AS Thesises_Prof1
		, f.ThesisesProf2 AS Thesises_Prof2
		FROM StudentInfo d
		INNER JOIN StudenList e ON e.student_id = d.StudentID 
		LEFT JOIN (
			SELECT c.Student_id
				, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
				, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
				, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id 
				AND a.task_detail_id = b.task_detail_id 
				AND b.fieldname IN('ThesisName', 'ThesisesProf1', 'ThesisesProf2') 
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
			INNER JOIN StudenList e ON e.student_id = c.Student_ID
			WHERE a.use_yn = 1 
			GROUP BY c.student_id
		) f ON d.StudentID = f.student_id
		WHERE (d.NganhID = @Decision_NganhID OR ISNULL(@Decision_NganhID, 0) = 0);
	END

	DECLARE @SLHV_BANGSO INT = (SELECT COUNT(*) FROM @tb);

	-- Result set 1: Thông tin quyết định
	SELECT D.[Decision_ID]
	, CASE WHEN LEN(D.[Decision_SoQD]) > 20 OR ISNULL(D.[Decision_SoQD],'') = '' THEN N'            /QĐ-ĐHLH' ELSE D.[Decision_SoQD] END AS Decision_SoQD
	, CASE WHEN ISNULL(D.[Decision_NgayQD],'') = '' THEN '     ' ELSE D.[Decision_NgayQD] END AS Decision_NgayQD
	, CASE WHEN ISNULL(D.[Decision_ThangQD],'')= '' THEN '     ' ELSE D.[Decision_ThangQD] END Decision_ThangQD
	, CASE WHEN ISNULL(D.[Decision_NamQD],'')= '' THEN ' 20    ' ELSE D.[Decision_NamQD] END AS Decision_NamQD
	, D.[Decision_TieuDe]
	, D.[Decision_NganhID]
	, D.[Decision_Nganh]
	, D.[Decision_NienKhoa]
	, D.[Decision_Dot]
	, D.[Decision_MaSo]
	, D.[Decision_Type]
	, D.[Decision_Description]
	, D.[DecisionFile_ID]
	, D.[DecisionFile_Url]
	, D.[DecisionFile_Name]
	, D.[Decision_TemplateID]
	, D.[Decision_Status]
	, CONVERT(INT, RIGHT(D.Created_By,4)) AS Decision_NguoiTao
	, @SLHV_BANGSO AS Decision_SLHVBangSo
	, [dbo].Num2Text(@SLHV_BANGSO) AS Decision_SLHVBangChu
	FROM [dbo].[Decision] D 
	WHERE D.Decision_ID = @Decision_ID;
	
	-- Result set 2: Danh sách học viên (áp dụng cho tất cả các loại quyết định có học viên)
	WITH cte AS (
		SELECT 
			ROW_NUMBER() OVER (PARTITION BY tb.Student_ID ORDER BY Thesises_Prof1) AS rn,
			ROW_NUMBER() OVER (ORDER BY Thesises_Prof1) AS STT,
			tb.Student_ID,
			PS.Process_ID,
			Ho_SV,
			Ten_SV,
			Ngay_Sinh,
			Noi_Sinh,
			Lop_ID,
			Ten_Nganh,
			Nien_Khoa,
			Thesis_Name,
			Thesises_Prof1,
			Thesises_Prof2
		FROM @tb tb
		LEFT JOIN Process_Student PS ON PS.Student_ID = tb.Student_ID
	)
	SELECT 
		ROW_NUMBER() OVER (ORDER BY Thesises_Prof1) AS STT,
		c.Student_ID,
		Process_ID,
		Ho_SV,
		Ten_SV,
		Ngay_Sinh,
		Noi_Sinh,
		Lop_ID,
		Ten_Nganh,
		si.NganhID,
		Nien_Khoa,
		Thesis_Name,
		Thesises_Prof1,
		Thesises_Prof2,
		gv1.Email_GV AS Email_GVHD1,
		gv1.SoDienThoai AS SoDT_GVHD1,
		gv1.CoQuanCongTac AS CoQuanCongTac_GVHD1,
		gv2.Email_GV AS Email_GVHD2,
		gv2.SoDienThoai AS SoDT_GVHD2,
		gv2.CoQuanCongTac AS CoQuanCongTac_GVHD2
	FROM cte c
	INNER JOIN StudentInfo si ON si.StudentID = c.Student_ID
	OUTER APPLY (
		SELECT TOP 1 Email_GV, SoDienThoai, CoQuanCongTac
		FROM GiangVien 
		WHERE c.Thesises_Prof1 = CONCAT(HocViHocHam, '. ', HoTenGiangVien)
	) gv1
	OUTER APPLY (
		SELECT TOP 1 Email_GV, SoDienThoai, CoQuanCongTac
		FROM GiangVien 
		WHERE c.Thesises_Prof2 = CONCAT(HocViHocHam, '. ', HoTenGiangVien)
	) gv2
	WHERE c.rn = 1
	ORDER BY Thesises_Prof1;

	-- Result set 3: File đính kèm
	SELECT [Decision_DetailID], [Decision_ID], [DecisionFile_ID], [DecisionFile_Url], [DecisionFile_Name], [Decision_Status], [Created_By], [Created_At] 
	FROM [dbo].[Decision_Detail] DT 
	WHERE DT.Decision_ID = @Decision_ID;
END
