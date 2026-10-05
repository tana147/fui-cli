CREATE PROC [dbo].[spAPI_Student_INS_obj]
@StudentObjArr NVARCHAR(MAX),
@Process_Action INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT,
@sys_GroupID INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF @Process_Action = 4
	BEGIN
		-- Tiến sĩ: FunctionRight = 2 (hoặc SystemRight = 9 admin)
		IF (@sys_SystemRight <> 9 AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE
	BEGIN
		-- Thạc sĩ: giữ như cũ
		IF (@sys_SystemRight NOT IN (2,3,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END

	CREATE TABLE #TempStudentInfo
	(
		[StudentID] VARCHAR(9),
		[MaHoSo] VARCHAR(20),
		[HoSV] NVARCHAR(50),
		[TenSV] NVARCHAR(30),
		[LopID] VARCHAR(9),
		[KhoaID] VARCHAR(3),
		[NganhID] VARCHAR(10),
		[TenNganh] NVARCHAR(200),
		[HeDaoTaoID] INT,
		[HeDaoTao] NVARCHAR(20),
		[NienKhoa] VARCHAR(9),
		[NgaySinh] VARCHAR(10),
		[NoiSinh] NVARCHAR(200),
		[GioiTinh] NVARCHAR(5),
		[SoDienThoai] VARCHAR(15),
		[Email] VARCHAR(100)
	);
	INSERT INTO #TempStudentInfo
	SELECT
		  json.StudentID
		, json.MaHoSo
		, json.HoSV
		, json.TenSV
		, json.LopID
		, json.KhoaID
		, json.NganhID
		, Nganh.TenNganh
		, json.HeDaoTaoID
		, Nganh.HeDaoTao
		, json.NienKhoa
		, json.NgaySinh
		, json.NoiSinh
		, json.GioiTinh
		, json.SoDienThoai
		, json.Email
	FROM OPENJSON(@StudentObjArr)
	WITH (
			StudentID VARCHAR(9),
			MaHoSo VARCHAR(20),
			HoSV NVARCHAR(50),
			TenSV NVARCHAR(30),
			LopID VARCHAR(9),
			KhoaID VARCHAR(3),
			NganhID VARCHAR(10),
			HeDaoTaoID INT,
			HeDaoTao NVARCHAR(20),
			NienKhoa VARCHAR(9),
			NgaySinh VARCHAR(10),
			NoiSinh NVARCHAR(200),
			GioiTinh NVARCHAR(5),
			SoDienThoai VARCHAR(15),
			Email VARCHAR(100)
	) AS json INNER JOIN Nganh ON json.NganhID = Nganh.NganhID;

	IF @Process_Action = 4
	BEGIN
		IF EXISTS (
			SELECT 1 FROM #TempStudentInfo 
			WHERE StudentID IS NULL 
			   OR LEN(LTRIM(RTRIM(StudentID))) <> 9 
			   OR StudentID LIKE '%[^0-9]%'
		)
		BEGIN
			SET @MsgError = N'Mã số học viên không hợp lệ. Đối với Tiến sĩ, mã học viên bắt buộc phải đúng chuẩn 9 chữ số (không dùng mã tạm HS1, HS2...).'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END

	DECLARE @StudentID VARCHAR(9)
	DECLARE @HeDaoTao NVARCHAR(50)
	DECLARE @NienKhoa VARCHAR(10)
	DECLARE @ProcessID_1 INT 
	DECLARE @ProcessID_2 INT
	DECLARE @ProcessID_3 INT
	
	WHILE (SELECT COUNT(*) FROM #TempStudentInfo) > 0
	BEGIN
		SELECT TOP 1 @StudentID = T.StudentID,  @HeDaoTao = T.HeDaoTao, @NienKhoa = T.NienKhoa FROM #TempStudentInfo T

		IF  NOT EXISTS (SELECT TOP 1 S.StudentID FROM StudentInfo S WHERE S.StudentID = @StudentID)
		BEGIN
			--INSERT VÀO TABLE StudentInfo
			INSERT INTO [dbo].[StudentInfo]
			(
				[StudentID]
				, [MaHoSo]
				, [HoSV]
				, [TenSV]
				, [LopID]
				, [KhoaID]
				, [NganhID]
				, [TenNganh]
				, [HeDaoTaoID]
				, [HeDaoTao]
				, [NienKhoa]
				, [NgaySinh]
				, [NoiSinh]
				, [GioiTinh]
				, [SoDienThoai]
				, [Email]
				, [IsXuLyHocVu]
				, [IsHoanThanhThacSi]
				, [CreateUser]
				, [CreateTime]
			)
			SELECT [StudentID]
				, ISNULL(NULLIF(LTRIM(RTRIM(T.MaHoSo)), ''), T.StudentID)
				, [HoSV]
				, [TenSV]
				, [LopID]
				, [KhoaID]
				, [NganhID]
				, [TenNganh]
				, [HeDaoTaoID]
				, [HeDaoTao]
				, [NienKhoa]
				, [NgaySinh]
				, [NoiSinh]
				, [GioiTinh]
				, [SoDienThoai]
				, [Email]
				, 0
				, 0
				, @SYS_UserID
				, GETDATE()
				FROM #TempStudentInfo T WHERE T.StudentID = @StudentID

			IF @@ROWCOUNT > 0  -- NẾU INSERT THÀNH CÔNG THÌ GỌI FLOW TƯƠNG ỨNG

			BEGIN
				--SET @ProcessID_1 = (SELECT P.Process_ID FROM Process P WHERE P.Process_Action = 1 AND P.Process_Type = @HeDaoTao AND P.Process_Status = 0)
				--SET @ProcessID_2 = (SELECT P.Process_ID FROM Process P WHERE P.Process_Action = 2 AND P.Process_Type = @HeDaoTao AND P.Process_Status = 0)
				--SET @ProcessID_3 = (SELECT P.Process_ID FROM Process P WHERE P.Process_Action = 3 AND P.Process_Type = @HeDaoTao AND P.Process_Status = 0)
				
				EXEC spAPI_Process_Student_Ins @Process_Action, @StudentID, NULL, @SYS_UserID, 1, @sys_SystemRight, @sys_GroupID, @sys_FunctionRight
				--EXEC [spAPI_PROCESS_STUDENT_INSERT] @ProcessID_2, @StudentID, NULL, @SYS_UserID, 1
				--EXEC [spAPI_PROCESS_STUDENT_INSERT] @ProcessID_3, @StudentID, NULL, @SYS_UserID, 1
			END
		END

		-- Trường hợp StudentInfo đã có data HV, nhưng Process_Student lại chưa có
		DECLARE @StudentInfo_Student_ID VARCHAR(9)
		DECLARE @ProcessStudent_Student_ID VARCHAR(9)

		SELECT TOP 1 @StudentInfo_Student_ID = StudentID
		FROM StudentInfo
		WHERE StudentID = @StudentID

		SELECT TOP 1 @ProcessStudent_Student_ID = Student_ID
		FROM Process_Student
		WHERE Student_ID = @StudentID

		IF @StudentInfo_Student_ID IS NOT NULL AND @ProcessStudent_Student_ID IS NULL
		BEGIN
			EXEC spAPI_Process_Student_Ins @Process_Action, @StudentID, NULL, @SYS_UserID, 1, @sys_SystemRight, @sys_GroupID, @sys_FunctionRight
		END

		DELETE #TempStudentInfo WHERE StudentID = @StudentID
	END
END
