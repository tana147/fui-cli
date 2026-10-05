CREATE PROC [dbo].[spAPI_HoiDong_Ins]
@Student_ID VARCHAR(9)
,@HoiDongThanhVienObj_Arr NVARCHAR(MAX)
,@ThoiGianBaoVe VARCHAR(10)
,@LoaiHoiDong INT
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @DecisionID INT
	DECLARE @HoiDongID INT
	DECLARE @TenDeTai NVARCHAR(500)
	DECLARE @HeDaoTao VARCHAR(20)
	DECLARE @Decision_Type NVARCHAR(50) = N'DGLVCH'
	DECLARE @Decision_TieuDe NVARCHAR(500) = N'Về việc thành lập Hội đồng đánh giá Luận văn Thạc sĩ'

	SET @LoaiHoiDong = ISNULL(@LoaiHoiDong, 1)

	SELECT @HeDaoTao = ISNULL(HeDaoTao, '') FROM StudentInfo WHERE StudentID = @Student_ID

	IF (@HeDaoTao = 'Phd' OR @HeDaoTao LIKE N'%Tiến sĩ%')
	BEGIN
		IF (@LoaiHoiDong = 1 OR @LoaiHoiDong = 0) SET @LoaiHoiDong = 2 -- Nếu truyền 1 hoặc 0 cho Tiến sĩ thì mặc định sang Chuyên đề 1

		IF (@LoaiHoiDong = 2)
		BEGIN
			SET @Decision_Type = N'QDBVCD1'
			SET @Decision_TieuDe = N'Về việc thành lập Hội đồng đánh giá Chuyên đề 1 NCS'
		END
		ELSE IF (@LoaiHoiDong = 3)
		BEGIN
			SET @Decision_Type = N'QDBVCD2'
			SET @Decision_TieuDe = N'Về việc thành lập Hội đồng đánh giá Chuyên đề 2 NCS'
		END
		ELSE IF (@LoaiHoiDong = 4)
		BEGIN
			SET @Decision_Type = N'QDBVCD3'
			SET @Decision_TieuDe = N'Về việc thành lập Hội đồng đánh giá Chuyên đề 3 NCS'
		END
		ELSE IF (@LoaiHoiDong = 5)
		BEGIN
			SET @Decision_Type = N'DGLATS'
			SET @Decision_TieuDe = N'Về việc thành lập Hội đồng đánh giá Luận án Tiến sĩ'
		END

		SELECT @TenDeTai = MAX(CASE WHEN fieldname IN ('ThesisNameNew', 'ThesisName', 'DangKyDeTai') THEN text_content ELSE NULL END) 
		FROM flow_detail a 
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameNew', 'ThesisName', 'DangKyDeTai') 
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.use_yn = 1
		WHERE a.use_yn = 1 AND c.Student_ID = @Student_ID

		IF (@TenDeTai IS NULL OR LTRIM(RTRIM(@TenDeTai)) = '')
		BEGIN
			SET @TenDeTai = N'Nghiên cứu ứng dụng chuyên sâu Tiến sĩ'
		END
	END
	ELSE
	BEGIN
		SET @LoaiHoiDong = 1
		SET @Decision_Type = N'DGLVCH'
		SET @Decision_TieuDe = N'Về việc thành lập Hội đồng đánh giá Luận văn Thạc sĩ'

		-- Lấy theo Process_Student active mới nhất của Thạc sĩ
		DECLARE @Process_Stu_ID_ThS INT
		SELECT TOP 1 @Process_Stu_ID_ThS = Process_Stu_ID
		FROM Process_Student
		WHERE Student_ID = @Student_ID AND Process_ID IN (1, 4) AND use_yn = 1 AND Process_Student_Status <> 'X'
		ORDER BY Process_Stu_ID DESC

		-- 1. Ưu tiên ThesisNameDefend (Đăng ký bảo vệ luận văn - Bước 3)
		SELECT TOP 1 @TenDeTai = a.text_content
		FROM flow_detail a 
		INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameDefend'
		INNER JOIN flow c ON a.flow_id = c.flow_id AND c.process_id IN (1, 4) AND c.use_yn = 1
		WHERE a.use_yn = 1 AND c.Student_ID = @Student_ID AND (c.Process_Student_ID = @Process_Stu_ID_ThS OR @Process_Stu_ID_ThS IS NULL)
		  AND a.text_content IS NOT NULL AND LTRIM(RTRIM(a.text_content)) <> ''
		ORDER BY a.Updated_At DESC

		-- 2. Ưu tiên ThesisNameNew (Nếu có quyết định đổi tên đề tài)
		IF (@TenDeTai IS NULL OR LTRIM(RTRIM(@TenDeTai)) = '')
		BEGIN
			SELECT TOP 1 @TenDeTai = a.text_content
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisNameNew'
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.process_id IN (1, 4) AND c.use_yn = 1
			WHERE a.use_yn = 1 AND c.Student_ID = @Student_ID AND (c.Process_Student_ID = @Process_Stu_ID_ThS OR @Process_Stu_ID_ThS IS NULL)
			  AND a.text_content IS NOT NULL AND LTRIM(RTRIM(@TenDeTai)) <> ''
			ORDER BY a.Updated_At DESC
		END

		-- 3. Fallback về ThesisName (Bước 1 - Nộp đề cương)
		IF (@TenDeTai IS NULL OR LTRIM(RTRIM(@TenDeTai)) = '')
		BEGIN
			SELECT TOP 1 @TenDeTai = a.text_content
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname = 'ThesisName'
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.process_id IN (1, 4) AND c.use_yn = 1
			WHERE a.use_yn = 1 AND c.Student_ID = @Student_ID AND (c.Process_Student_ID = @Process_Stu_ID_ThS OR @Process_Stu_ID_ThS IS NULL)
			  AND a.text_content IS NOT NULL AND LTRIM(RTRIM(a.text_content)) <> ''
			ORDER BY a.Updated_At DESC
		END

		-- 4. Fallback toàn bộ nếu cây active chưa có dữ liệu
		IF (@TenDeTai IS NULL OR LTRIM(RTRIM(@TenDeTai)) = '')
		BEGIN
			SELECT TOP 1 @TenDeTai = a.text_content
			FROM flow_detail a 
			INNER JOIN task_detail b ON a.task_id = b.task_id AND a.task_detail_id = b.task_detail_id AND b.fieldname IN ('ThesisNameDefend', 'ThesisNameNew', 'ThesisName')
			INNER JOIN flow c ON a.flow_id = c.flow_id AND c.process_id IN (1, 4) AND c.use_yn = 1
			WHERE a.use_yn = 1 AND c.Student_ID = @Student_ID
			  AND a.text_content IS NOT NULL AND LTRIM(RTRIM(a.text_content)) <> ''
			ORDER BY a.Updated_At DESC
		END
	END

	INSERT INTO Decision([Decision_TieuDe], [Decision_NganhID], [Decision_Nganh], [Decision_MaSo], [Decision_Type],  [Created_By], [Created_At])
	SELECT @Decision_TieuDe AS [Decision_TieuDe]
		, S.NganhID
		, N.TenNganh 
		, N.MaNganh
		, @Decision_Type
		, @SYS_UserID
		, GETDATE()
	FROM StudentInfo S INNER JOIN Nganh N ON S.NganhID = N.NganhID
	WHERE S.StudentID = @Student_ID
	
	SET @DecisionID = @@IDENTITY

	INSERT INTO HoiDong([StudentID], [DeTai], [Decision_ID], [LoaiHoiDong],[ThoiGianBaoVe], [Created_By], [Created_At], Is_PublishDiem)
	VALUES (@Student_ID, @TenDeTai, @DecisionID, @LoaiHoiDong, @ThoiGianBaoVe, @SYS_UserID, GETDATE(), 0)

	SET @HoiDongID = @@IDENTITY

	UPDATE Decision SET HoiDong_ID = @HoiDongID WHERE Decision_ID = @DecisionID

	INSERT INTO HoiDongThanhVien
	(
		HoiDongID,
		StudentID,
		GiangVienID,
		HocViHocHam,
		HoTenGiangVien,
		CoQuanCongTac,
		NganhGiangDay,
		ChucTrach,
		Created_By,
		Created_At,
		Is_PublishDiem
	)
	SELECT 
		@HoiDongID,
		@Student_ID,
		GiangVienID,
		HocViHocHam,
		HoTenGiangVien,
		CoQuanCongTac,
		NganhGiangDay,
		ChucTrach,
		@SYS_UserID,
		GETDATE(),
		0
	FROM OPENJSON (@HoiDongThanhVienObj_Arr)
	WITH 
	(
		GiangVienID INT '$.GiangVienID',
		HocViHocHam NVARCHAR(10) '$.HocViHocHam',
		HoTenGiangVien NVARCHAR(50) '$.HoTenGiangVien',
		CoQuanCongTac NVARCHAR(500) '$.CoQuanCongTac',
		NganhGiangDay NVARCHAR(200) '$.NganhGiangDay',
		ChucTrach NVARCHAR(50) '$.ChucTrach'
	)

	SELECT @DecisionID AS DecisionID, @HoiDongID AS HoiDongID

END
