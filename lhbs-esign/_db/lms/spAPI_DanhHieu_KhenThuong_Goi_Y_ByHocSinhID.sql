CREATE PROC [dbo].[spAPI_DanhHieu_KhenThuong_Goi_Y_ByHocSinhID] 
	@HocSinhID INT,
	@NienKhoa INT,
	@Semester VARCHAR(20)
AS 
BEGIN 
	SET NOCOUNT ON;
	
	DECLARE @CapID INT = 1;
	DECLARE @LopID VARCHAR(20) = 0;
	DECLARE @KhoiID INT = 0;
	
	-- Lấy LopID và Khối của học sinh
	SELECT @LopID = HSL.LopID, @KhoiID = L.KhoiID
	FROM dbo.tblHocSinhLop HSL  
		INNER JOIN dbo.tblLop L ON L.LopID = HSL.LopID 
			AND L.NienKhoa = @NienKhoa 
			AND L.Enable = 1 
	AND HSL.NienKhoa = L.NienKhoa
        WHERE HocSinhID = @HocSinhID;
	
	-- Định nghĩa môn học tính điểm theo khối
	DECLARE @MonHocTinhDiem TABLE(MonHocID INT, KhoiID INT);
	
	-- Khối 1, 2: Toán + Tiếng Việt + Ngoại ngữ
	INSERT INTO @MonHocTinhDiem VALUES (2, 1), (1, 1), (5, 1);
	INSERT INTO @MonHocTinhDiem VALUES (2, 2), (1, 2), (5, 2);
	
	-- Khối 3: Toán + Tiếng Việt + Công Nghệ + Ngoại ngữ + Tin học
	INSERT INTO @MonHocTinhDiem VALUES (2, 3), (1, 3), (35, 3), (5, 3), (6, 3);
	
	-- Khối 4, 5: Toán + Tiếng Việt + Công Nghệ + Khoa học + Lịch Sử-Địa Lí + Ngoại ngữ + Tin học
	INSERT INTO @MonHocTinhDiem VALUES (2, 4), (1, 4), (35, 4), (4, 4), (19, 4), (5, 4), (6, 4);
	INSERT INTO @MonHocTinhDiem VALUES (2, 5), (1, 5), (35, 5), (4, 5), (19, 5), (5, 5), (6, 5);
	
	-- Lấy danh sách môn học đang có
	DECLARE @Table_MonHoc_DangCo TABLE(MonHocID INT, KhoiID INT, IsNLPC BIT);
	INSERT INTO @Table_MonHoc_DangCo  
	SELECT DISTINCT mh.MonHocID, l.KhoiID, Is_MonHoc_NLPC 
	FROM dbo.tblMonHocLop mhl 
		INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID 
			AND mh.Enable = 1 
			AND mh.CapID = @CapID 
		INNER JOIN dbo.tblLop l ON l.LopID = mhl.LopNhomID 
			AND l.Enable = 1 
			AND l.NienKhoa = @NienKhoa 
	WHERE mhl.Enable = 1 
		AND mhl.NienKhoa = @NienKhoa  
		AND mhl.LopNhomID = @LopID;
	
	-- 1. Lấy kết quả đánh giá các môn học (Hoàn thành tốt/Hoàn thành/Chưa hoàn thành)
	DECLARE @Table_MonHoc TABLE(
		MonHocID INT,
		KhoiID INT,
		KetQua NVARCHAR(200)
	);
	
	INSERT INTO @Table_MonHoc
	SELECT 
		mhl.MonHocID,
		l.KhoiID,
		kqht.KetQuaDanhGia_VI
	FROM dbo.tblKetQuaHocTap kqht 
		INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID 
			AND ct.Enable = 1 
			AND ct.Semester = @Semester
			AND ct.MaCotDiem LIKE 'MucDoDanhGia%'
			AND ct.MaNhomCotDiem LIKE '%CK_' + @Semester
		INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID 
			AND mhl.Enable = 1 
			AND mhl.NienKhoa = @NienKhoa 
		INNER JOIN dbo.tblLop l ON l.LopID = mhl.LopNhomID 
			AND l.NienKhoa = @NienKhoa 
			AND l.Enable = 1
		INNER JOIN @Table_MonHoc_DangCo t ON t.KhoiID = l.KhoiID 
			AND t.MonHocID = mhl.MonHocID 
			AND ISNULL(t.IsNLPC, 0) = 0
	WHERE kqht.NienKhoa = @NienKhoa 
		AND kqht.Enable = 1 
		AND HocSinhID = @HocSinhID;

	-- 2. Lấy kết quả đánh giá Phẩm chất, Năng lực (Tốt/Đạt/Chưa đạt)
	DECLARE @Table_MonHoc_MucDo_PCNL TABLE(
		MonHocID INT,
		KhoiID INT,
		KetQua NVARCHAR(200)
	);
	
	INSERT INTO @Table_MonHoc_MucDo_PCNL
	SELECT 
		mhl.MonHocID,
		l.KhoiID,
		kqht.KetQuaDanhGia_VI
	FROM dbo.tblKetQuaHocTap kqht 
		INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID 
			AND ct.Enable = 1 
			AND ct.Semester = @Semester
			AND ct.MaCotDiem LIKE 'MucDoDanhGia%'
			AND ct.MaNhomCotDiem LIKE '%CK_' + @Semester
		INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID 
			AND mhl.Enable = 1 
			AND mhl.NienKhoa = @NienKhoa 
		INNER JOIN dbo.tblLop l ON l.LopID = mhl.LopNhomID 
			AND l.NienKhoa = @NienKhoa 
			AND l.Enable = 1
		INNER JOIN @Table_MonHoc_DangCo t ON t.KhoiID = l.KhoiID 
			AND t.MonHocID = mhl.MonHocID 
			AND ISNULL(t.IsNLPC, 0) = 1
	WHERE kqht.NienKhoa = @NienKhoa 
		AND kqht.Enable = 1 
		AND HocSinhID = @HocSinhID;
	
	-- 3. Lấy điểm kiểm tra định kỳ cuối kỳ các môn (CHỈ MÔN TÍNH ĐIỂM)
	DECLARE @Table_MonHoc_Diem TABLE(
		MonHocID INT, 
		KhoiID INT, 
		DiemSo DECIMAL(4,2) 
	);
	
	INSERT INTO @Table_MonHoc_Diem 
	SELECT 
		mhl.MonHocID, 
		l.KhoiID,
		TRY_CAST(kqht.KetQuaDanhGia_VI AS DECIMAL(4,2)) AS DiemSo
	FROM dbo.tblKetQuaHocTap kqht 
		INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID 
			AND ct.Enable = 1 
			AND ct.Semester = @Semester
			AND ct.MaCotDiem LIKE 'Diem%'
			AND ct.MaNhomCotDiem LIKE '%CK_' + @Semester
		INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID 
			AND mhl.Enable = 1 
			AND mhl.NienKhoa = @NienKhoa 
		INNER JOIN dbo.tblLop l ON l.LopID = mhl.LopNhomID 
			AND l.NienKhoa = @NienKhoa 
			AND l.Enable = 1
		INNER JOIN @MonHocTinhDiem mtd ON mtd.MonHocID = mhl.MonHocID 
			AND mtd.KhoiID = l.KhoiID
	WHERE kqht.NienKhoa = @NienKhoa 
		AND kqht.Enable = 1 
		AND HocSinhID = @HocSinhID;

	-- PHÂN TÍCH ĐIỀU KIỆN ĐẠT DANH HIỆU
	DECLARE @TongMonHocTinhDiem INT = 0;
	DECLARE @TongMonHocCoKetQua INT = 0;
	DECLARE @TongMonHocHoanThanhTot INT = 0;
	DECLARE @TongPCNL INT = 0;
	DECLARE @TongPCNL_Tot INT = 0;
	DECLARE @DiemThapNhat DECIMAL(4,2) = NULL;
	DECLARE @DiemTrungBinh DECIMAL(4,2) = NULL;
	
	-- Đếm số môn tính điểm
	SELECT @TongMonHocTinhDiem = COUNT(DISTINCT MonHocID) 
	FROM @MonHocTinhDiem 
	WHERE KhoiID = @KhoiID;
	
	-- Đếm số môn có kết quả đánh giá "Hoàn thành tốt"
	SELECT 
		@TongMonHocCoKetQua = COUNT(*),
		@TongMonHocHoanThanhTot = SUM(CASE WHEN KetQua = N'Hoàn thành tốt' THEN 1 ELSE 0 END)
	FROM @Table_MonHoc
	WHERE MonHocID IN (SELECT MonHocID FROM @MonHocTinhDiem WHERE KhoiID = @KhoiID);
	
	-- Đếm số Phẩm chất/Năng lực đạt "Tốt"
	SELECT 
		@TongPCNL = COUNT(*),
		@TongPCNL_Tot = SUM(CASE WHEN KetQua = N'Tốt' THEN 1 ELSE 0 END)
	FROM @Table_MonHoc_MucDo_PCNL;
	
	-- Tính điểm thấp nhất và trung bình
	SELECT 
		@DiemThapNhat = MIN(DiemSo),
		@DiemTrungBinh = AVG(DiemSo)
	FROM @Table_MonHoc_Diem;
	
	-- XÁC ĐỊNH DANH HIỆU
	DECLARE @DatXuatSac BIT = 0;
	DECLARE @DatTieuBieu BIT = 0;
	DECLARE @DanhHieuGoiY NVARCHAR(200) = N'Chưa đủ điều kiện';
	DECLARE @LyDo NVARCHAR(MAX) = '';
	DECLARE @ChiTiet NVARCHAR(MAX) = '';
	
	-- Kiểm tra điều kiện đầy đủ
	IF @TongMonHocCoKetQua = @TongMonHocTinhDiem 
		AND @TongPCNL > 0 
		AND @DiemThapNhat IS NOT NULL
	BEGIN
		SET @ChiTiet = N'Thống kê: ' + CHAR(13) + CHAR(10) +
					   N'• Môn học: ' + CAST(@TongMonHocHoanThanhTot AS NVARCHAR) + N'/' + 
					   CAST(@TongMonHocTinhDiem AS NVARCHAR) + N' môn đạt "Hoàn thành tốt"' + CHAR(13) + CHAR(10) +
					   N'• Phẩm chất/Năng lực: ' + CAST(@TongPCNL_Tot AS NVARCHAR) + N'/' + 
					   CAST(@TongPCNL AS NVARCHAR) + N' đạt mức "Tốt"' + CHAR(13) + CHAR(10) +
					   N'• Điểm kiểm tra: Thấp nhất ' + CAST(@DiemThapNhat AS NVARCHAR) + 
					   N', Trung bình ' + CAST(CAST(@DiemTrungBinh AS DECIMAL(4,1)) AS NVARCHAR);
		
		-- Điều kiện Học sinh Xuất sắc
		IF @TongMonHocHoanThanhTot = @TongMonHocTinhDiem  -- Tất cả môn "Hoàn thành tốt"
			AND @TongPCNL_Tot = @TongPCNL                 -- Tất cả PCNL đạt "Tốt"
			AND @DiemThapNhat >= 9.0                      -- Tất cả điểm ≥ 9.0
		BEGIN
			SET @DatXuatSac = 1;
			SET @DanhHieuGoiY = N'Học sinh Xuất sắc';
			SET @LyDo = N'✓ ĐẠT điều kiện "Học sinh Xuất sắc":' + CHAR(13) + CHAR(10) +
						N'1. Tất cả ' + CAST(@TongMonHocTinhDiem AS NVARCHAR) + 
						N' môn học (khối ' + CAST(@KhoiID AS NVARCHAR) + N') đạt "Hoàn thành tốt"' + CHAR(13) + CHAR(10) +
						N'2. Tất cả ' + CAST(@TongPCNL AS NVARCHAR) + 
						N' phẩm chất, năng lực đạt mức "Tốt"' + CHAR(13) + CHAR(10) +
						N'3. Điểm kiểm tra định kỳ cuối kỳ tất cả môn ≥ 9.0' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
						@ChiTiet;
		END
		-- Điều kiện Học sinh Tiêu biểu
		ELSE IF @TongMonHocHoanThanhTot = @TongMonHocTinhDiem  -- Tất cả môn "Hoàn thành tốt"
			AND @TongPCNL_Tot = @TongPCNL                      -- Tất cả PCNL đạt "Tốt"
			AND @DiemThapNhat >= 7.0                           -- Tất cả điểm ≥ 7.0
		BEGIN
			SET @DatTieuBieu = 1;
			SET @DanhHieuGoiY = N'Học sinh Tiêu biểu hoàn thành tốt trong học tập và rèn luyện';
			SET @LyDo = N'✓ ĐẠT điều kiện cơ bản "Học sinh Tiêu biểu":' + CHAR(13) + CHAR(10) +
						N'1. Tất cả ' + CAST(@TongMonHocTinhDiem AS NVARCHAR) + 
						N' môn học (khối ' + CAST(@KhoiID AS NVARCHAR) + N') đạt "Hoàn thành tốt"' + CHAR(13) + CHAR(10) +
						N'2. Tất cả ' + CAST(@TongPCNL AS NVARCHAR) + 
						N' phẩm chất, năng lực đạt mức "Tốt"' + CHAR(13) + CHAR(10) +
						N'3. Điểm kiểm tra định kỳ cuối kỳ tất cả môn ≥ 7.0' + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
						@ChiTiet + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) +
						N'⚠ LƯU Ý: Cần xác nhận thêm:' + CHAR(13) + CHAR(10) +
						N'• Có thành tích xuất sắc ở ít nhất 1 môn học HOẶC tiến bộ rõ rệt ở ít nhất 1 phẩm chất/năng lực' + CHAR(13) + CHAR(10) +
						N'• Được tập thể lớp và Hội đồng công nhận';
		END
		ELSE
		BEGIN
			SET @LyDo = N'✗ CHƯA ĐẠT điều kiện vì:' + CHAR(13) + CHAR(10);
			
			IF @TongMonHocHoanThanhTot < @TongMonHocTinhDiem
				SET @LyDo = @LyDo + N'• Chỉ ' + CAST(@TongMonHocHoanThanhTot AS NVARCHAR) + N'/' + 
							CAST(@TongMonHocTinhDiem AS NVARCHAR) + 
							N' môn đạt "Hoàn thành tốt"' + CHAR(13) + CHAR(10);
			
			IF @TongPCNL_Tot < @TongPCNL
				SET @LyDo = @LyDo + N'• Chỉ ' + CAST(@TongPCNL_Tot AS NVARCHAR) + N'/' + 
							CAST(@TongPCNL AS NVARCHAR) + 
							N' phẩm chất/năng lực đạt "Tốt"' + CHAR(13) + CHAR(10);
			
			IF @DiemThapNhat < 7.0
				SET @LyDo = @LyDo + N'• Điểm kiểm tra thấp nhất chỉ đạt ' + 
							CAST(@DiemThapNhat AS NVARCHAR) + N' (< 7.0)' + CHAR(13) + CHAR(10);
			
			SET @LyDo = @LyDo + CHAR(13) + CHAR(10) + @ChiTiet;
		END
	END
	ELSE
	BEGIN
		SET @LyDo = N'✗ CHƯA ĐỦ DỮ LIỆU để đánh giá:' + CHAR(13) + CHAR(10);
		
		IF @TongMonHocCoKetQua < @TongMonHocTinhDiem
			SET @LyDo = @LyDo + N'• Môn học: Chỉ ' + CAST(@TongMonHocCoKetQua AS NVARCHAR) + N'/' + 
						CAST(@TongMonHocTinhDiem AS NVARCHAR) + N' môn có kết quả đánh giá' + CHAR(13) + CHAR(10);
		
		IF @TongPCNL = 0
			SET @LyDo = @LyDo + N'• Chưa có kết quả đánh giá Phẩm chất/Năng lực' + CHAR(13) + CHAR(10);
		
		IF @DiemThapNhat IS NULL
			SET @LyDo = @LyDo + N'• Chưa có điểm kiểm tra định kỳ cuối kỳ' + CHAR(13) + CHAR(10);
	END
	
	-- TRẢ VỀ KẾT QUẢ TỔNG QUAN
	SELECT 
		@HocSinhID AS HocSinhID,
		@KhoiID AS KhoiID,
		@DanhHieuGoiY AS DanhHieuGoiY,
		@DatXuatSac AS DatDieuKienXuatSac,
		@DatTieuBieu AS DatDieuKienTieuBieu,
		@LyDo AS LyDo,
		@TongMonHocTinhDiem AS TongMonHocTinhDiem,
		@TongMonHocCoKetQua AS SoMonHocCoKetQua,
		@TongMonHocHoanThanhTot AS SoMonHocHoanThanhTot,
		@TongPCNL AS TongPCNL,
		@TongPCNL_Tot AS SoPCNL_DatTot,
		@DiemThapNhat AS DiemThapNhat,
		@DiemTrungBinh AS DiemTrungBinh;
	
	-- CHI TIẾT CÁC MÔN HỌC (CHỈ MÔN TÍNH ĐIỂM)
	SELECT 
		mh.MonHocID,
		mh.TenMonHoc_HienThi,
		kq.KetQua AS KetQuaDanhGia,
		d.DiemSo AS DiemKiemTra,
		CASE 
			WHEN kq.KetQua = N'Hoàn thành tốt' AND d.DiemSo >= 9.0 THEN N'✓ Đạt Xuất sắc'
			WHEN kq.KetQua = N'Hoàn thành tốt' AND d.DiemSo >= 7.0 THEN N'✓ Đạt Tiêu biểu'
			WHEN kq.KetQua IS NULL THEN N'✗ Chưa có đánh giá'
			WHEN d.DiemSo IS NULL THEN N'✗ Chưa có điểm'
			WHEN kq.KetQua <> N'Hoàn thành tốt' THEN N'✗ Chưa đạt "Hoàn thành tốt"'
			WHEN d.DiemSo < 7.0 THEN N'✗ Điểm < 7.0'
			ELSE N'✗ Chưa đạt'
		END AS NhanXet
	FROM @MonHocTinhDiem mtd
		INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = mtd.MonHocID
		LEFT JOIN @Table_MonHoc kq ON kq.MonHocID = mtd.MonHocID
		LEFT JOIN @Table_MonHoc_Diem d ON d.MonHocID = mtd.MonHocID
	WHERE mtd.KhoiID = @KhoiID
	ORDER BY mh.TenMonHoc_HienThi;
	
	-- CHI TIẾT PHẨM CHẤT, NĂNG LỰC
	SELECT 
		mh.MonHocID,
		mh.TenMonHoc_HienThi,
		pc.KetQua AS MucDoDanhGia,
		CASE 
			WHEN pc.KetQua = N'Tốt' THEN N'✓ Đạt mức "Tốt"'
			WHEN pc.KetQua IS NULL THEN N'✗ Chưa có đánh giá'
			ELSE N'✗ Chưa đạt "Tốt"'
		END AS NhanXet
	FROM @Table_MonHoc_DangCo t
		INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = t.MonHocID
		LEFT JOIN @Table_MonHoc_MucDo_PCNL pc ON pc.MonHocID = t.MonHocID
	WHERE ISNULL(t.IsNLPC, 0) = 1
	ORDER BY mh.TenMonHoc_HienThi;
	
END
