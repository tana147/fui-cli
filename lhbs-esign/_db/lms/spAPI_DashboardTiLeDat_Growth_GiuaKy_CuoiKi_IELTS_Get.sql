-- [dbo].[spAPI_DashboardTiLeDat_Growth_GiuaKy_CuoiKi_IELTS_Get] 3 , 76,2024, 1 
CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Growth_GiuaKy_CuoiKi_IELTS_Get]
    @CapID INT,
	@MonHocID INT,
    @NienKhoa NVARCHAR(50),
    @HocKy INT -- thêm tham số học kỳ
AS
BEGIN
    SET NOCOUNT ON;

    -- Xác định cột giữa kỳ và cuối kỳ theo học kỳ
    DECLARE @MidCot NVARCHAR(50);
    DECLARE @FinalCot NVARCHAR(50);

    IF @HocKy = 1
    BEGIN
        SET @MidCot = 'S1_Mid_IELTS_Band_Conv';
        SET @FinalCot = 'S1_Final_IELTS_Band_Conv';
    END
    ELSE IF @HocKy = 2
    BEGIN
        SET @MidCot = 'S2_Mid_IELTS_Band_Conv';
        SET @FinalCot = 'S2_Final_IELTS_Band_Conv';
    END
    ELSE
    BEGIN
        THROW 50000, 'HocKy không hợp lệ. Chỉ nhận 1 hoặc 2.', 1;
    END

    -- Tạo bảng tạm để lưu kết quả trung gian
    DECLARE @KetQuaGoc AS TABLE(
		KhoiID INT,
        NhomID VARCHAR(9),
        TenNhom NVARCHAR(100),
		HocSinhID VARCHAR(9),
        DiemGK_HK1 DECIMAL(10,2),
        DiemCK_HK1 DECIMAL(10,2)
    );

    -- Truy vấn dữ liệu thực tế và chuẩn hóa kết quả đánh giá
    INSERT INTO @KetQuaGoc (KhoiID, NhomID, TenNhom, HocSinhID, DiemGK_HK1, DiemCK_HK1)
	SELECT 
		tl.KhoiID,
		tl.NhomID,
		tl.TenNhom,
		hs.HocSinhID,
		MAX(CASE 
			WHEN tbdct.MaCotDiem = @MidCot
			THEN TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2))
			ELSE NULL
		END) AS DiemGK_HK1,
		MAX(CASE 
			WHEN tbdct.MaCotDiem = @FinalCot
			THEN TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2))
			ELSE NULL
		END) AS DiemCK_HK1
	FROM 
		dbo.tblKetQuaHocTap tkqht
		INNER JOIN dbo.tblHocSinh hs ON tkqht.HocSinhID = hs.HocSinhID
		INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID
		INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
		INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
		INNER JOIN dbo.tblNhom tl ON tl.NhomID = tkqht.LopID and tl.IsNhomLMS_GiaoBai = 0
	WHERE 
		tbdct.MaCotDiem IN (@MidCot, @FinalCot)
		AND tkqht.NienKhoa = @NienKhoa
		AND tmh.MonHocID = @MonHocID
		AND tl.CapID = @CapID
		AND tkqht.Enable = 1
	GROUP BY 
		tl.KhoiID,
		tl.NhomID,
		tl.TenNhom,
		hs.HocSinhID;

	-- Đếm tổng số học sinh và số học sinh có điểm cuối kỳ cao hơn điểm giữa kỳ
	DECLARE @TongSoHocSinh INT;
	DECLARE @SoHocSinhCaoHon INT;

	SELECT @TongSoHocSinh = COUNT(*) FROM @KetQuaGoc;

	SELECT @SoHocSinhCaoHon = COUNT(*) 
	FROM @KetQuaGoc
	WHERE DiemCK_HK1 > DiemGK_HK1;

	DECLARE @TiLe FLOAT;
	SET @TiLe = CASE 
					WHEN @TongSoHocSinh > 0 THEN ROUND((@SoHocSinhCaoHon * 100.0 / @TongSoHocSinh), 2)
					ELSE 0
				END;

	-- In kết quả tổng
	SELECT 
		@TongSoHocSinh AS TongSoHocSinh,
		@SoHocSinhCaoHon AS SoHocSinhCaoHon,
		@TiLe AS TiLePhanTram;

	-- Tính theo từng khối
	SELECT 
		KhoiID,
		COUNT(*) AS TongSoHocSinh,
		SUM(CASE WHEN DiemCK_HK1 > DiemGK_HK1 THEN 1 ELSE 0 END) AS SoHocSinhCaoHon,
		CASE 
			WHEN COUNT(*) > 0 THEN ROUND((SUM(CASE WHEN DiemCK_HK1 > DiemGK_HK1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2)
			ELSE 0
		END AS TiLePhanTram
	FROM 
		@KetQuaGoc
	GROUP BY 
		KhoiID;

	-- Tính theo từng nhóm
	SELECT 
		KhoiID,
		NhomID,
		TenNhom,
		COUNT(*) AS TongSoHocSinh,
		SUM(CASE WHEN DiemCK_HK1 > DiemGK_HK1 THEN 1 ELSE 0 END) AS SoHocSinhCaoHon,
		CASE 
			WHEN COUNT(*) > 0 THEN ROUND((SUM(CASE WHEN DiemCK_HK1 > DiemGK_HK1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2)
			ELSE 0
		END AS TiLePhanTram
	FROM 
		@KetQuaGoc
	GROUP BY 
		KhoiID,
		NhomID,
		TenNhom;
END;
