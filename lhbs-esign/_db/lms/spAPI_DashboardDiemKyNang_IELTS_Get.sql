
CREATE PROCEDURE [dbo].[spAPI_DashboardDiemKyNang_IELTS_Get]
    @NienKhoa INT,
    @CapID INT,
    @MonHocID INT,
    @MaNhomDiem NVARCHAR(MAX), -- Chuỗi các MaCotDiem, phân tách bằng dấu phẩy
	@KhoiID INT,
	@Is_KyNang BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Tách chuỗi MaCotDiem thành bảng tạm
    DECLARE @MaNhomDiemTable TABLE (MaNhomDiem NVARCHAR(50));
    INSERT INTO @MaNhomDiemTable (MaNhomDiem)
    SELECT LTRIM(RTRIM(value)) -- Sử dụng LTRIM và RTRIM thay thế TRIM
    FROM STRING_SPLIT(@MaNhomDiem, ',');

	DECLARE @ExcludedCotDiem TABLE (MaCotDiem NVARCHAR(50));
	IF @Is_KyNang = 1
	BEGIN
			INSERT INTO @ExcludedCotDiem VALUES
			
										('S1_Mid_IELTS_Band_Conv'), 
										('S1_Final_IELTS_Band_Conv'), 
										('S2_Final_IELTS_Band_Conv'), 
										('S2_Final_IELTS_Band_Conv');
	END
	ELSE
	BEGIN
			INSERT INTO @ExcludedCotDiem VALUES
			('S1_Mid_IELTS_Listening_Conv'),
			('S1_Mid_IELTS_Reading_Conv'),
			('S1_Mid_IELTS_Writing_Conv'),
			('S1_Mid_IELTS_Speaking_Conv');
									  
	END

   
	 SELECT 
			@CapID AS CapID,
			tl.KhoiID,
			N'Khối '  + CAST (tl.KhoiID AS VARCHAR) AS TenKhoi,
            tkqht.LopID,
            tl.TenNhom as TenLop,
			hs.HocSinhID,
			hs.Ho + N' ' + hs.Ten as HoTen, 
           -- tmh.MonHocName,
           -- tmh.MonHocCode,
			tbdct.MaNhomCotDiem,
			tbdct.TenNhomCotDiem_VI,
			tbdct.TenNhomCotDiem_EN,
            tbdct.MaCotDiem,
			tbdct.TenCotDiem_VI,
			tbdct.TenCotDiem_EN,
            CASE 
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
                     AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN 
                    CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                ELSE NULL
            END AS Diem,
            tbdct.ThuTuCotDiem -- Thứ tự cột điểm
        FROM 
            dbo.tblKetQuaHocTap tkqht
        INNER JOIN 
            dbo.tblNhom tl ON tl.NhomID = tkqht.LopID and tl.IsNhomLMS_GiaoBai = 0
		INNER JOIN 
            dbo.tblHocSinh hs ON hs.HocSinhID = tkqht.HocSinhID
        INNER JOIN 
            dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
        INNER JOIN 
            dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN 
            dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
		INNER JOIN 
			@MaNhomDiemTable tnd ON tnd.MaNhomDiem = tbdct.MaNhomCotDiem
        LEFT JOIN 
			@ExcludedCotDiem ex ON tbdct.MaCotDiem = ex.MaCotDiem
        WHERE 
            tkqht.NienKhoa = @NienKhoa
            AND tl.CapID = @CapID
			AND tl.KhoiID = @KhoiID
            AND tmh.MonHocID = @MonHocID
			and TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
			--AND MaCotDiem NOT IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point', 'S2_Mid_Total_Point' , 'S2_Final_Total_Point')
			AND ex.MaCotDiem IS NULL
			  AND  tkqht.Enable                      = 1
		ORDER BY  TenLop, ThuTuNhom, ThuTuCotDiem

END;