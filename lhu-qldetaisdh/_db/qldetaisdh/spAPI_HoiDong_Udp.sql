CREATE PROC [dbo].[spAPI_HoiDong_Udp]
@Student_ID VARCHAR(9)
,@HoiDong_ID INT
,@HoiDongThanhVienObj_Arr NVARCHAR(MAX)
,@ThoiGianBaoVe VARCHAR(10)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	UPDATE HoiDong
	SET ThoiGianBaoVe = @ThoiGianBaoVe 
		,Updated_By = @SYS_UserID
		, Updated_At = GETDATE()
	WHERE HoiDongID = @HoiDong_ID
	
	-----Update Thời gian bảo vệ ở Flow_Detail--------
	DECLARE @ProcessStuID INT
	DECLARE @ProcessID INT
	DECLARE @TaskID INT
	DECLARE @FlowID INT
	DECLARE @TaskDetailId INT

	SELECT 
	@ProcessStuID = Process_Stu_ID,
	@ProcessID = Process_ID
	FROM Process_Student
	WHERE Student_ID = @Student_ID AND Process_ID IN (1, 4) AND Process_Student_Status <> 'X'

	SELECT @TaskID = Task_ID
	FROM Tasks
	WHERE Task_Description = 'reviewThesis'  
	AND Task_Code = CASE 
					  WHEN @ProcessID = 1 THEN 'ThS04'
						ELSE 'ThSUD04'
					  END

	SELECT @FlowID = Flow_ID
	FROM Flow
	WHERE Process_Student_ID = @ProcessStuID 
	AND Task_ID = @TaskID

	SELECT @TaskDetailId = Task_Detail_ID
	FROM Task_Detail
	WHERE FieldName = 'QDThanhLapHoiDong_ThoiGian' AND Task_ID = @TaskID

	UPDATE Flow_Detail
	SET Text_Content = @ThoiGianBaoVe
	WHERE Flow_ID = @FlowID AND Task_Detail_ID = @TaskDetailId
	--------------------------------------------------

	IF ISJSON( @HoiDongThanhVienObj_Arr) > 0
	BEGIN
		--1.  Xóa hội đồng thành viên cũ
		UPDATE HoiDongThanhVien 
		SET Is_Xoa = 1,
			Updated_By = @SYS_UserID,
			Updated_At = GETDATE()
		WHERE HoiDongID = @HoiDong_ID

		--2. insert lại
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
			Created_At
		)
		SELECT 
			@HoiDong_ID,
			@Student_ID,
			GiangVienID,
			HocViHocHam,
			HoTenGiangVien,
			CoQuanCongTac,
			NganhGiangDay,
			ChucTrach,
			@SYS_UserID,
			GETDATE()
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
	END

	

END

