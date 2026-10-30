CREATE PROCEDURE dbo.spAPI_SoGVCNKeHoachTuanSaveBatch
	@SoGVCNID varchar(10),
	@Rows nvarchar(max),
	@sys_UserID varchar(10),
	@sys_SystemRight varchar(10)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	DECLARE @ID int = TRY_CONVERT(int, @SoGVCNID);
	DECLARE @RowCount int;
	DECLARE @LockResult int;
	DECLARE @LockResource nvarchar(255) = N'SoGVCNKeHoachTuan:' + CONVERT(nvarchar(10), @ID);

	IF @ID IS NULL OR ISNULL(ISJSON(@Rows), 0) <> 1 OR LEFT(LTRIM(@Rows), 1) <> N'['
		THROW 50001, N'Dữ liệu kế hoạch tuần không hợp lệ.', 1;

	SELECT Thang, ThangThucTe, TuanTrongThang, TuNgay, DenNgay,
		KeHoachThucHien, KetQua, NguyenNhan
	INTO #WeekInput
	FROM OPENJSON(@Rows) WITH (
		Thang varchar(20) '$.Thang',
		ThangThucTe varchar(20) '$.ThangThucTe',
		TuanTrongThang varchar(20) '$.TuanTrongThang',
		TuNgay varchar(20) '$.TuNgay',
		DenNgay varchar(20) '$.DenNgay',
		KeHoachThucHien nvarchar(max) '$.KeHoachThucHien',
		KetQua nvarchar(max) '$.KetQua',
		NguyenNhan nvarchar(max) '$.NguyenNhan'
	);

	SELECT @RowCount = COUNT(*) FROM #WeekInput;
	IF @RowCount > 60
		THROW 50002, N'Số dòng kế hoạch tuần vượt giới hạn.', 1;

	IF EXISTS (
		SELECT 1 FROM #WeekInput
		WHERE ISNULL(TRY_CONVERT(tinyint, Thang), 0) NOT BETWEEN 1 AND 12
			OR ISNULL(TRY_CONVERT(tinyint, ThangThucTe), 0) NOT BETWEEN 1 AND 12
			OR ISNULL(TRY_CONVERT(tinyint, TuanTrongThang), 0) NOT BETWEEN 1 AND 6
			OR TRY_CONVERT(date, TuNgay, 23) IS NULL
			OR TRY_CONVERT(date, DenNgay, 23) IS NULL
			OR TRY_CONVERT(date, TuNgay, 23) > TRY_CONVERT(date, DenNgay, 23)
	)
		THROW 50003, N'Tháng, tuần hoặc ngày trong kế hoạch không hợp lệ.', 1;

	IF EXISTS (
		SELECT 1 FROM #WeekInput
		GROUP BY TRY_CONVERT(tinyint, Thang),
			TRY_CONVERT(tinyint, ThangThucTe),
			TRY_CONVERT(tinyint, TuanTrongThang)
		HAVING COUNT(*) > 1
	)
		THROW 50004, N'Kế hoạch có tuần bị trùng.', 1;

	BEGIN TRY
		BEGIN TRAN;
		EXEC @LockResult = sys.sp_getapplock
			@Resource = @LockResource,
			@LockMode = 'Exclusive',
			@LockOwner = 'Transaction',
			@LockTimeout = 10000;
		IF @LockResult < 0
			THROW 50005, N'Không thể khóa kế hoạch tuần để lưu.', 1;

		SELECT m.KeHoachThangID,
			TRY_CONVERT(tinyint, i.ThangThucTe) AS ThangThucTe,
			TRY_CONVERT(tinyint, i.TuanTrongThang) AS TuanTrongThang,
			TRY_CONVERT(date, i.TuNgay, 23) AS TuNgay,
			TRY_CONVERT(date, i.DenNgay, 23) AS DenNgay,
			NULLIF(LTRIM(RTRIM(i.KeHoachThucHien)), N'') AS KeHoachThucHien,
			NULLIF(LTRIM(RTRIM(i.KetQua)), N'') AS KetQua,
			NULLIF(LTRIM(RTRIM(i.NguyenNhan)), N'') AS NguyenNhan
		INTO #Weeks
		FROM #WeekInput i
		JOIN dbo.tblSoGVCNKeHoachThang m
			ON m.SoGVCNID = @ID
			AND m.Thang = TRY_CONVERT(tinyint, i.Thang)
			AND m.Enable = 1;

		IF (SELECT COUNT(*) FROM #Weeks) <> @RowCount
			THROW 50006, N'Chưa có kế hoạch tháng tương ứng.', 1;

		-- Chỉ cập nhật tuần có trong payload; tuần vắng mặt được giữ nguyên để
		-- một bản tải thiếu hoặc lỗi trình duyệt không thể ẩn dữ liệu đã lưu.
		UPDATE w
		SET w.TuNgay = i.TuNgay,
			w.DenNgay = i.DenNgay,
			w.KeHoachThucHien = i.KeHoachThucHien,
			w.KetQua = i.KetQua,
			w.NguyenNhan = i.NguyenNhan,
			w.Enable = 1,
			w.UpdateUser = @sys_UserID,
			w.UpdateTime = GETDATE()
		FROM dbo.tblSoGVCNKeHoachTuan w
		JOIN #Weeks i
			ON i.KeHoachThangID = w.KeHoachThangID
			AND i.ThangThucTe = w.ThangThucTe
			AND i.TuanTrongThang = w.TuanTrongThang;

		INSERT INTO dbo.tblSoGVCNKeHoachTuan
			(KeHoachThangID, ThangThucTe, TuanTrongThang, TuNgay, DenNgay,
			 KeHoachThucHien, KetQua, NguyenNhan, CreateUser, UpdateUser)
		SELECT i.KeHoachThangID, i.ThangThucTe, i.TuanTrongThang,
			i.TuNgay, i.DenNgay, i.KeHoachThucHien, i.KetQua, i.NguyenNhan,
			@sys_UserID, @sys_UserID
		FROM #Weeks i
		WHERE NOT EXISTS (
			SELECT 1 FROM dbo.tblSoGVCNKeHoachTuan w WITH (UPDLOCK, HOLDLOCK)
			WHERE w.KeHoachThangID = i.KeHoachThangID
				AND w.ThangThucTe = i.ThangThucTe
				AND w.TuanTrongThang = i.TuanTrongThang
		);
		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN;
		THROW;
	END CATCH;

	SELECT mess = N'Đã lưu kế hoạch tuần', SoGVCNID = @ID, SavedRows = @RowCount;
END;
