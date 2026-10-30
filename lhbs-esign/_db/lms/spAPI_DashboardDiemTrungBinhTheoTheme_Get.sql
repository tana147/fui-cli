CREATE PROCEDURE [dbo].[spAPI_DashboardDiemTrungBinhTheoTheme_Get]
    @HocKy          NVARCHAR(10), -- Học kỳ: 'HK1' hoặc 'HK2'
    @KhoiID         INT,
    @LopID          VARCHAR(20),
    @MonHocID       INT,
    @HocSinhID          INT,
	@NienKhoa       INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm để chứa danh sách theme
    DECLARE  @ThemeList TABLE (Theme NVARCHAR(50));

    -- Chèn các theme tương ứng với học kỳ
    IF @HocKy = 'HK1'
    BEGIN
        INSERT INTO @ThemeList (Theme)
        VALUES ('Theme1_Total'), ('Theme2_Total'), ('Theme3_Total'), ('Theme4_Total'), ('S1_Mid_Total_Point'), ('S1_Final_Total_Point');
    END
    ELSE IF @HocKy = 'HK2'
    BEGIN
        INSERT INTO @ThemeList (Theme)
        VALUES ('Theme5_Total'), ('Theme6_Total'), ('Theme7_Total'), ('Theme8_Total'), ('S2_Mid_Total_Point'), ('S2_Final_Total_Point');
    END
	ELSE IF @HocKy = 'CN'
    BEGIN
        INSERT INTO @ThemeList (Theme)
        VALUES   ('Theme1_Total'), ('Theme2_Total'), ('Theme3_Total'), ('Theme4_Total'),('Theme5_Total'), ('Theme6_Total'), ('Theme7_Total'), ('Theme8_Total'),('S1_Mid_Total_Point'), ('S1_Final_Total_Point'), ('S2_Mid_Total_Point'), ('S2_Final_Total_Point');
    END
    ELSE
    BEGIN
        PRINT N'Học kỳ không hợp lệ! Chỉ chấp nhận HK1 hoặc HK2 hoặc CN';
        RETURN;
    END;

	DECLARE @IsNumber BIT

	SET @IsNumber = CASE 
                   WHEN TRY_CAST(@LopID AS INT) IS NOT NULL THEN 1
                   ELSE 0
                END
	IF(@IsNumber = 1)
	BEGIN
		-- Truy vấn dữ liệu
		SELECT 
			ths.Ho + ' ' + ths.Ten AS HoTen,
			tbdct.MaCotDiem,
			CASE WHEN tkqht.KetQuaDanhGia_VI = '' THEN NULL ELSE  tkqht.KetQuaDanhGia_VI END AS KetQuaDanhGia_VI ,
			tl.LopID,
			tl.TenKhoiPhanBan,
			tl.TenLop,
			tbdct.Semester,
			tbdct.DiemMin,
			tbdct.DiemMax
		FROM dbo.tblKetQuaHocTap tkqht
			INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID
			INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
			INNER JOIN dbo.tblLop tl ON tl.LopID = thsl.LopID AND tl.NienKhoa = @NienKhoa
			AND thsl.NienKhoa = tl.NienKhoa
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
			INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
			INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
		WHERE 
			tl.KhoiID = @KhoiID
			AND tmh.MonHocID = @MonHocID
			AND tl.LopID = CAST(@LopID as varchar(20))
			AND ths.HocSinhID = @HocSinhID
			AND (
			(@HocKy IN ('HK1', 'HK2') AND tbdct.Semester = @HocKy) OR
			(@HocKy = 'CN' AND tbdct.Semester IN ('HK1', 'HK2'))
		)	AND tkqht.NienKhoa = @NienKhoa
			AND tbdct.MaCotDiem IN (SELECT Theme FROM @ThemeList)
			AND  tkqht.Enable                      = 1;

		-- Dọn dẹp bảng tạm
		--DROP TABLE #ThemeList;

		-- Truy vấn dữ liệu
		SELECT 
			ths.Ho + ' ' + ths.Ten AS HoTen,
			tbdct.MaNhomCotDiem,
			tbdct.TenNhomCotDiem_EN,
			tbdct.MaCotDiem,
			tbdct.TenCotDiem_EN,
			CASE WHEN tkqht.KetQuaDanhGia_VI = '' THEN NULL ELSE  tkqht.KetQuaDanhGia_VI END AS KetQuaDanhGia_VI ,
			tl.LopID,
			tl.TenKhoiPhanBan,
			tl.TenLop,
			tbdct.Semester,
			tbdct.DiemMin,
			tbdct.DiemMax,
            tbdct.TemplateBangDiemID
		FROM dbo.tblKetQuaHocTap tkqht
		INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID
		INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
		INNER JOIN dbo.tblLop tl ON tl.LopID = thsl.LopID AND tl.NienKhoa = @NienKhoa
		AND thsl.NienKhoa = tl.NienKhoa
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
		INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
		INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
		WHERE 
			tl.KhoiID = @KhoiID
			AND tmh.MonHocID = @MonHocID
			AND tl.LopID =  CAST(@LopID as varchar(20))
			AND ths.HocSinhID = @HocSinhID
			AND (
				(@HocKy IN ('HK1', 'HK2') AND tbdct.Semester = @HocKy) OR
				(@HocKy = 'CN' AND tbdct.Semester IN ('HK1', 'HK2'))
			)
			AND tkqht.NienKhoa = @NienKhoa
			AND tbdct.GiaTriCotDiem = 'number'
			AND tbdct.MaCotDiem NOT LIKE '%_BNS_VNM%' AND tbdct.MaCotDiem NOT LIKE '%_BNS_EXP%'
			--AND ISNULL(tbdct.Formula,'') = ''
			  AND  tkqht.Enable                      = 1
		ORDER BY ThuTuNhom, ThuTuCotDiem
	END
	ELSE
BEGIN
    -- Truy vấn dữ liệu
    SELECT 
        ths.Ho + ' ' + ths.Ten AS HoTen,
        tbdct.MaCotDiem,
        tkqht.KetQuaDanhGia_VI,
        n.NhomID AS LopID,
        n.TenNhom AS TenLop,
        tbdct.Semester
    FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID
        INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
        INNER JOIN dbo.tblNhom n ON tkqht.LopID = n.NhomID and n.IsNhomLMS_GiaoBai = 0
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    WHERE 
        n.KhoiID = @KhoiID
        AND tmh.MonHocID = @MonHocID
        AND tkqht.LopID = CAST(@LopID AS VARCHAR(20))
        AND ths.HocSinhID = @HocSinhID
        AND (
            (@HocKy IN ('HK1', 'HK2') AND tbdct.Semester = @HocKy) OR
            (@HocKy = 'CN' AND tbdct.Semester IN ('HK1', 'HK2'))
        )
		AND tkqht.NienKhoa = @NienKhoa
        AND tbdct.MaCotDiem IN (SELECT Theme FROM @ThemeList)
        AND tkqht.Enable = 1;

    -- Dọn dẹp bảng tạm
    --DROP TABLE #ThemeList;

    -- Truy vấn dữ liệu
    SELECT 
        ths.Ho + ' ' + ths.Ten AS HoTen,
        tbdct.MaNhomCotDiem,
        tbdct.TenNhomCotDiem_EN,
        tbdct.MaCotDiem,
        tbdct.TenCotDiem_EN,
        tkqht.KetQuaDanhGia_VI,
        n.NhomID AS LopID,
        n.TenNhom AS TenLop,
        tbdct.Semester
    FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh ths ON tkqht.HocSinhID = ths.HocSinhID
        INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
        INNER JOIN dbo.tblNhom n ON tkqht.LopID = n.NhomID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmhl.MonHocID = tmh.MonHocID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    WHERE 
        n.KhoiID = @KhoiID
        AND tmh.MonHocID = @MonHocID
        AND tkqht.LopID = CAST(@LopID AS VARCHAR(20))
        AND ths.HocSinhID = @HocSinhID
        AND (
            (@HocKy IN ('HK1', 'HK2') AND tbdct.Semester = @HocKy) OR
            (@HocKy = 'CN' AND tbdct.Semester IN ('HK1', 'HK2'))
        )
		AND tkqht.NienKhoa = @NienKhoa
        AND tbdct.GiaTriCotDiem = 'number'
        AND tbdct.MaCotDiem NOT LIKE '%_BNS_VNM%' 
        AND tbdct.MaCotDiem NOT LIKE '%_BNS_EXP%'
        AND ISNULL(tbdct.Formula,'') = ''
        AND tkqht.Enable = 1
    ORDER BY ThuTuNhom, ThuTuCotDiem, MaNhomCotDiem, MaCotDiem;

END

END;