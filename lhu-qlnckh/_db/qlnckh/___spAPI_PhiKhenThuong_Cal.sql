--}
--{"AnPhamID":2650,"CongThucKhenThuongID":6,"DiemHoiDong":"0.75","HeSo_IF":"2.6","HeSoChatLuongID":3}
--  [dbo].[spAPI_PhiKhenThuong_Cal] 6891, 1, 0.75, 0, 0
CREATE PROC [dbo].[___spAPI_PhiKhenThuong_Cal]
@AnPhamID INT,
@CongThucKhenThuongID INT,
@DiemHoiDong FLOAT,
@HeSo_IF FLOAT,
@HeSoChatLuongID INT
AS
BEGIN
	

	DECLARE @TongSoTacGia INT , @SoTacGia_LHU INT, @HinhThucThanhToan TINYINT, @NhomAnPham TINYINT  , @LoaiSubAnPhamID INT
	SET @TongSoTacGia= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0)
	SET @SoTacGia_LHU= (SELECT COUNT(*) FROM AnPham_TacGia WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0 AND TacGiaGroupID IN (1,2))
	SELECT @HinhThucThanhToan = HinhThucThanhToan,  @NhomAnPham = NhomAnPham, @LoaiSubAnPhamID = LoaiSubAnPhamID FROM AnPham WHERE AnPhamID = @AnPhamID AND Is_Xoa = 0
	 
	DECLARE @DiemHeSoChatLuong NUMERIC(18,2)
	SET @DiemHeSoChatLuong = (SELECT DiemHeSoChatLuong FROM HeSoChatLuong HS WHERE HS.HeSoChatLuongID = @HeSoChatLuongID)



	DECLARE @tacgia AS TABLE(AnPhamTacGiaID INT, ViTri INT, AP_Index FLOAT, KhenThuong NUMERIC(18,2), Is_NhanVien BIT, TacGiaGroupID INT, NguoiDaiDienQuyetToan BIT, HeSoHoTroCaoHoc FLOAT)
	INSERT INTO @tacgia(AnPhamTacGiaID , ViTri , AP_Index , KhenThuong, Is_NhanVien, TacGiaGroupID, NguoiDaiDienQuyetToan, HeSoHoTroCaoHoc)
	SELECT  A.AnPhamTacGiaID, ROW_NUMBER() OVER (ORDER BY A.AnPhamTacGiaID), AP_Index, 0, Is_NhanVien, TacGiaGroupID, A.NguoiDaiDienQuyetToan, A.HeSoHoTroCaoHoc
	FROM AnPham_TacGia A
	WHERE A.AnPhamID = @AnPhamID AND A.Is_Xoa = 0


	

	DECLARE @STT INT =1
	WHILE @STT < (SELECT COUNT(*) FROM @tacgia) + 1
	BEGIN
		PRINT @STT
		DECLARE @AP FLOAT
		DECLARE @HeSoHoTroCaoHoc FLOAT
		DECLARE @KhenThuong NUMERIC(18,2)
		DECLARE @tblKT AS TABLE(VT INT IDENTITY(1, 1), KT NUMERIC(18,2))
		DECLARE @NguoiDaiDienQuyetToan INT
		SELECT @AP = AP_Index
		, @HeSoHoTroCaoHoc = ISNULL(HeSoHoTroCaoHoc,1)
		, @NguoiDaiDienQuyetToan =  NguoiDaiDienQuyetToan 
		FROM @tacgia WHERE ViTri = @STT
		SET @DiemHeSoChatLuong = ISNULL(@DiemHeSoChatLuong,0)

		IF @HeSo_IF > 5 --Theo yêu cầu TTNCKH nếu IF > 5 thì chỉ tính là 5
		BEGIN
			SET @HeSo_IF = 5 
		END
		
		IF @NhomAnPham = 2  AND @CongThucKhenThuongID = 2 --NhomAnPham =2 :Hỗ trợ đầu vào cao học; @CongThucKhenThuongID = 2 : Tạp chí Khoa học Lạc Hồng
		BEGIN
			
			INSERT INTO @tblKT(KT)
			EXEC [dbo].[CalculatePayment] @CongThucKhenThuongID, @DiemHoiDong, @AP, @TongSoTacGia, @HeSo_IF, @DiemHeSoChatLuong


			SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT  WHERE VT = @STT) 
			print 'hesohotrocaohoc'
			print @HeSoHoTroCaoHoc
			print 'stt'
			print @stt

			UPDATE @tacgia 
			SET KhenThuong = CASE WHEN @NguoiDaiDienQuyetToan = 1 THEN 5000000 * ISNULL(@HeSoHoTroCaoHoc,1) ELSE 0 END
			WHERE ViTri = @STT
		END
		ELSE IF @NhomAnPham = 2  AND @CongThucKhenThuongID = 1 --NhomAnPham =2 :Hỗ trợ đầu vào cao học; @CongThucKhenThuongID = 1 : Hội đồng GSNN
		BEGIN
			INSERT INTO @tblKT(KT)
			EXEC [dbo].[CalculatePayment] @CongThucKhenThuongID, @DiemHoiDong, @AP, @TongSoTacGia, @HeSo_IF, @DiemHeSoChatLuong


			SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT  WHERE VT = @STT) * ISNULL(@HeSoHoTroCaoHoc,1)

			UPDATE @tacgia 
			SET KhenThuong = CASE WHEN @NguoiDaiDienQuyetToan = 1 THEN 3000000 * ISNULL(@HeSoHoTroCaoHoc,1) ELSE 0 END
			WHERE ViTri = @STT
		END
		--ELSE IF @CongThucKhenThuongID BETWEEN 13 AND 30
  --      BEGIN
  --          -- Thưởng MOU: tính theo BÀI (một cục cho cả nhóm), không nhân theo tác giả
  --          IF @STT = 1
  --          BEGIN
  --              INSERT INTO @tblKT(KT)
  --              EXEC [dbo].[CalculatePayment] 
  --                   @CongThucKhenThuongID, @DiemHoiDong, /*@AP không dùng nhưng để nguyên*/ @AP, 
  --                   @TongSoTacGia, @HeSo_IF, @DiemHeSoChatLuong;

  --              SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT ORDER BY VT);

  --              -- Nếu muốn nhân hệ số hỗ trợ cao học cho người nhận cục tiền, giữ như dưới.
  --              UPDATE @tacgia
  --              SET KhenThuong = @KhenThuong * ISNULL(@HeSoHoTroCaoHoc, 1)
  --              WHERE ViTri = @STT;
  --          END
  --          ELSE
  --          BEGIN
  --              -- Các vị trí còn lại bằng 0
  --              UPDATE @tacgia
  --              SET KhenThuong = 0
  --              WHERE ViTri = @STT;
  --          END
  --      END
		ELSE IF (@CongThucKhenThuongID BETWEEN 13 AND 30) OR (@CongThucKhenThuongID BETWEEN 32 AND 41)
		BEGIN
			-- Thưởng MOU: tính theo BÀI (một cục cho cả nhóm)
			-- Chỉ cần gọi CalculatePayment 1 lần duy nhất (không phụ thuộc tác giả)
			IF @STT = 1
			BEGIN
				INSERT INTO @tblKT(KT)
				EXEC [dbo].[CalculatePayment] 
					 @CongThucKhenThuongID, @DiemHoiDong, @AP, 
					 @TongSoTacGia, @HeSo_IF, @DiemHeSoChatLuong;

				SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT ORDER BY VT DESC);

				IF @HinhThucThanhToan = 1
				BEGIN
					-- Đại diện 1 người nhận toàn bộ
					UPDATE @tacgia
					SET KhenThuong = CASE 
							WHEN NguoiDaiDienQuyetToan = 1 
							THEN @KhenThuong * ISNULL(HeSoHoTroCaoHoc, 1)
							ELSE 0 
						END;
					-- Đã update hết → nhảy STT tới cuối để thoát loop
					SET @STT = (SELECT COUNT(*) FROM @tacgia);
				END
				ELSE -- @HinhThucThanhToan = 2: Phân bổ cho các thành viên LHU
				BEGIN
					IF @SoTacGia_LHU > 0
					BEGIN
						UPDATE @tacgia
						SET KhenThuong = CASE 
								WHEN TacGiaGroupID IN (1, 2) 
								THEN ROUND((@KhenThuong / @SoTacGia_LHU) * ISNULL(HeSoHoTroCaoHoc, 1), 0)
								ELSE 0 
							END;
					END
					ELSE
					BEGIN
						-- Không có tác giả LHU → gán hết cho vị trí đầu
						UPDATE @tacgia
						SET KhenThuong = CASE 
								WHEN ViTri = 1 THEN @KhenThuong 
								ELSE 0 
							END;
					END
					SET @STT = (SELECT COUNT(*) FROM @tacgia);
				END
			END
		END
		ELSE
		BEGIN
			INSERT INTO @tblKT(KT)
			EXEC [dbo].[CalculatePayment] @CongThucKhenThuongID, @DiemHoiDong, @AP, @TongSoTacGia, @HeSo_IF, @DiemHeSoChatLuong


			SET @KhenThuong = (SELECT TOP 1 KT FROM @tblKT  WHERE VT = @STT)
			print @STT
			print ('Khen thuong: ' +  convert(varchar(50), @KhenThuong) )
			print ('vao day' + convert(varchar(5), @HeSoHoTroCaoHoc))

			UPDATE @tacgia 
			SET KhenThuong = CASE WHEN TacGiaGroupID IN (1,2) THEN   @KhenThuong * @HeSoHoTroCaoHoc ELSE 0 END
			WHERE ViTri = @STT

			--select * from @tacgia
		END

		
		
		SET @STT = @STT + 1
		
	END
	--1: Đại diện 1 thành viên nhận ; 2: Phân bổ cho các thành viên; 
	IF @HinhThucThanhToan = 1
	BEGIN
		--DECLARE @TongKhenThuong NUMERIC(18,2)
		--SET @TongKhenThuong = (SELECT SUM(ISNULL(KhenThuong,0)) FROM @tacgia)
		
		--UPDATE @tacgia
		--SET KhenThuong = @TongKhenThuong
		--WHERE NguoiDaiDienQuyetToan = 1
		
		--UPDATE @tacgia
		--SET KhenThuong = 0
		--WHERE NguoiDaiDienQuyetToan = 0

		DECLARE @TongKhenThuong NUMERIC(18,2) = (SELECT SUM(ISNULL(KhenThuong,0)) FROM @tacgia);

		IF EXISTS (SELECT 1 FROM @tacgia WHERE NguoiDaiDienQuyetToan = 1)
		BEGIN
			UPDATE @tacgia SET KhenThuong = @TongKhenThuong WHERE NguoiDaiDienQuyetToan = 1;
			UPDATE @tacgia SET KhenThuong = 0 WHERE NguoiDaiDienQuyetToan = 0;
		END
		ELSE
		BEGIN
			IF (SELECT COUNT(*) FROM @tacgia) = 1
				UPDATE @tacgia SET KhenThuong = @TongKhenThuong; -- 1 tác giả: nhận hết
			-- else: giữ nguyên phân bổ đã tính (hoặc tự set ViTri=1 làm đại diện tùy quy chế)
		END
	END

	SELECT * FROM @tacgia
END


