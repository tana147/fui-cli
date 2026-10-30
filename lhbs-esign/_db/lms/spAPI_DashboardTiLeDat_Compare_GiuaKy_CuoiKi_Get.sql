

-- [spAPI_DashboardTiLeDat_Compare_GiuaKy_CuoiKi_Get] 7, 0,46, 2024
CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Compare_GiuaKy_CuoiKi_Get]
    @KhoiID INT,
    @LopID INT ,
	@MonHocID INT,
    @NienKhoa NVARCHAR(50),
    @HocKi INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm để lưu kết quả trung gian
    CREATE TABLE #KetQuaGoc (
        LopID VARCHAR(9),
        TenLop VARCHAR(9),
        MaCotDiem VARCHAR(50),
        KetQuaDanhGia_VI NVARCHAR(100),
        SoLuong INT DEFAULT 0,
        TyLe DECIMAL(5,2) DEFAULT 0,
        ThuTuNhom INT DEFAULT 99
    );

    -- Dữ liệu mặc định để đảm bảo luôn có 6 dòng
    CREATE TABLE #DuLieuMacDinh (
        MaCotDiem VARCHAR(50),
        KetQuaDanhGia_VI NVARCHAR(100),
        ThuTuNhom INT
    );

    INSERT INTO #DuLieuMacDinh (MaCotDiem, KetQuaDanhGia_VI, ThuTuNhom)
    VALUES 
        ('S1_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu'))), 1),
        ('S1_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu'))), 2),
        ('S1_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt'))), 3),
        ('S1_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu'))), 4),
        ('S1_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu'))), 5),
        ('S1_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt'))), 6),
		('S2_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu'))), 7),
        ('S2_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu'))), 8),
        ('S2_Mid_Total_Conv',   LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt'))), 9),
        ('S2_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu'))), 10),
        ('S2_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu'))), 11),
        ('S2_Final_Total_Conv', LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt'))), 12);

    -- Truy vấn dữ liệu thực tế và chuẩn hóa kết quả đánh giá
    INSERT INTO #KetQuaGoc (LopID, TenLop, MaCotDiem, KetQuaDanhGia_VI, SoLuong, ThuTuNhom)
    SELECT 
        tl.LopID,
        tl.TenLop,
        tbdct.MaCotDiem,
         CASE WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%exceeding requirements%'     THEN      LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu')))
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%meeting requirements%'     THEN    LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu')))
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%not meeting requirements%' THEN    LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt')))
	                                                                                                ELSE N'Không xác định' END AS KetQuaDanhGia_VI,
        COUNT(*) AS SoLuong,
        ISNULL(tbdct.ThuTuNhom, 99) AS ThuTuNhom
    FROM 
        dbo.tblKetQuaHocTap tkqht
       INNER JOIN dbo.tblHocSinh              hs    ON tkqht.HocSinhID = hs.HocSinhID AND   hs.TinhTrang= 0
		INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID AND tbdct.Enable = 1
		INNER JOIN dbo.tblMonHocLop            tmhl  ON tmhl.MonHocLopID = tkqht.MonHocLopID AND tmhl.Enable =1
		INNER JOIN dbo.tblMonHoc               tmh   ON tmh.MonHocID = tmhl.MonHocID AND  tmh.Enable =1
		INNER JOIN dbo.tblLop                tl    ON tl.LopID = tkqht.LopID AND tl.Enable = 1 AND tl.NienKhoa = @NienKhoa
    WHERE 
        (
            (@HocKi = 1 AND tbdct.MaCotDiem IN ('S1_Mid_Total_Conv','S1_Final_Total_Conv'))
         OR (@HocKi = 2 AND tbdct.MaCotDiem IN ('S2_Mid_Total_Conv','S2_Final_Total_Conv'))
        )
		AND tmh.MonHocID = @MonHocID
        AND tkqht.NienKhoa = @NienKhoa
        AND 
        (
            (tl.KhoiID = @KhoiID AND @LopID = 0)
            OR 
            (tl.KhoiID = @KhoiID AND tl.LopID = @LopID)
        )
		  AND  tkqht.Enable                      = 1
    GROUP BY 
        tl.LopID,
        tl.TenLop,
        tbdct.MaCotDiem,
          CASE WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%exceeding requirements%'    THEN      LOWER(LTRIM(RTRIM(N'Exceeding Requirements/Vượt yêu cầu')))
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%meeting requirements%'     THEN    LOWER(LTRIM(RTRIM(N'Meeting Requirements/Đạt yêu cầu')))
	            WHEN LOWER(LTRIM(RTRIM(tkqht.KetQuaDanhGia_VI))) LIKE N'%not meeting requirements%' THEN    LOWER(LTRIM(RTRIM(N'Not Meeting Requirements/Chưa đạt')))
	                                                                                                ELSE N'Không xác định'
        END,
        tbdct.ThuTuNhom;

    -- Bổ sung dữ liệu mặc định nếu thiếu
    INSERT INTO #KetQuaGoc (LopID, TenLop, MaCotDiem, KetQuaDanhGia_VI, ThuTuNhom)
    SELECT DISTINCT 
        LopID,
        TenLop,
        d.MaCotDiem,
        d.KetQuaDanhGia_VI,
        d.ThuTuNhom
    FROM 
        #KetQuaGoc g
        CROSS JOIN #DuLieuMacDinh d
    WHERE 
        NOT EXISTS (
            SELECT 1 
            FROM #KetQuaGoc
            WHERE LopID = g.LopID 
              AND MaCotDiem = d.MaCotDiem 
              AND LOWER(LTRIM(RTRIM(KetQuaDanhGia_VI))) = LOWER(LTRIM(RTRIM(d.KetQuaDanhGia_VI)))
        );

    -- Tính tỷ lệ
    DECLARE @TongSoLuong INT;
    SELECT @TongSoLuong = SUM(SoLuong) FROM #KetQuaGoc;

    IF @TongSoLuong > 0
    BEGIN
       UPDATE KG
		SET TyLe = CASE WHEN T.TongSoLuongTheoNhom > 0 THEN ROUND(CAST(KG.SoLuong AS DECIMAL(10, 2)) * 100.0 / T.TongSoLuongTheoNhom, 2)
		                                               ELSE 0 END
		FROM        #KetQuaGoc    KG
		CROSS APPLY (
			SELECT SUM(SoLuong) AS TongSoLuongTheoNhom
			FROM #KetQuaGoc
			WHERE LopID = KG.LopID
				AND MaCotDiem = KG.MaCotDiem
			)                  AS T;
    END;

    -- Trả về kết quả
    SELECT 
        LopID,
        TenLop,
        MaCotDiem,
        KetQuaDanhGia_VI,
        SoLuong,
        TyLe,
        ThuTuNhom
    FROM #KetQuaGoc
    ORDER BY 
        TenLop,
        ThuTuNhom;

    -- Dọn dẹp bảng tạm
    DROP TABLE #KetQuaGoc;
    DROP TABLE #DuLieuMacDinh;
END;

