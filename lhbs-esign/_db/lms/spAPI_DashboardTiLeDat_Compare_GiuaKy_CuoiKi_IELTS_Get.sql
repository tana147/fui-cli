
-- [spAPI_DashboardTiLeDat_Compare_GiuaKy_CuoiKi_IELTS_Get] 12, 0, 76, 2024
CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Compare_GiuaKy_CuoiKi_IELTS_Get]
    @KhoiID INT,
    @NhomID INT,
    @MonHocID INT,
    @NienKhoa NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm để lưu kết quả trung gian
    CREATE TABLE #KetQuaGoc (
        NhomID VARCHAR(9),
        TenNhom VARCHAR(9),
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
        ('S1_Mid_IELTS_Band_Conv', N'Exceeding Requirements/Vượt yêu cầu', 1),
        ('S1_Mid_IELTS_Band_Conv', N'Meeting Requirements/Đạt yêu cầu', 2),
        ('S1_Mid_IELTS_Band_Conv', N'Not Meeting Requirements/Chưa đạt', 3),
        ('S1_Final_IELTS_Band_Conv', N'Exceeding Requirements/Vượt yêu cầu', 4),
        ('S1_Final_IELTS_Band_Conv', N'Meeting Requirements/Đạt yêu cầu', 5),
        ('S1_Final_IELTS_Band_Conv', N'Not Meeting Requirements/Chưa đạt', 6);

    -- Truy vấn dữ liệu thực tế và chuẩn hóa kết quả đánh giá
    INSERT INTO #KetQuaGoc (NhomID, TenNhom, MaCotDiem, KetQuaDanhGia_VI, SoLuong, ThuTuNhom)
    SELECT 
        tn.NhomID,
        tn.TenNhom,
        tbdct.MaCotDiem,
        CASE 
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Vượt yêu cầu', N'Exceeding Requirements', N'Exceeding Requirements/ Vượt yêu cầu') 
                THEN N'Exceeding Requirements/Vượt yêu cầu'
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Đạt yêu cầu', N'Meeting Requirements', N'Meeting Requirements/Đạt yêu cầu') 
                THEN N'Meeting Requirements/Đạt yêu cầu'
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Chưa đạt', N'Not Meeting Requirements', N'Not Meeting Requirements/Chưa đạt', N'Not Meeting Requirements/ Chưa đạt') 
                THEN N'Not Meeting Requirements/Chưa đạt'
            ELSE N'Không xác định'
        END AS KetQuaDanhGia_VI,
        COUNT(*) AS SoLuong,
        ISNULL(tbdct.ThuTuNhom, 99) AS ThuTuNhom
    FROM 
        dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh hs ON tkqht.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        INNER JOIN dbo.tblNhom tn ON tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0
    WHERE 
        tbdct.MaCotDiem IN ('S1_Mid_IELTS_Band_Conv','S1_Final_IELTS_Band_Conv')
		AND tmh.MonHocID = @MonHocID
        AND tkqht.NienKhoa = @NienKhoa
        AND 
        (
            (tn.KhoiID = @KhoiID AND @NhomID = 0)
            OR 
            (tn.KhoiID = @KhoiID AND tn.NhomID = @NhomID)
        )
        AND tkqht.Enable = 1
    GROUP BY 
        tn.NhomID,
        tn.TenNhom,
        tbdct.MaCotDiem,
        CASE 
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Vượt yêu cầu', N'Exceeding Requirements', N'Exceeding Requirements/ Vượt yêu cầu') 
                THEN N'Exceeding Requirements/Vượt yêu cầu'
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Đạt yêu cầu', N'Meeting Requirements', N'Meeting Requirements/Đạt yêu cầu') 
                THEN N'Meeting Requirements/Đạt yêu cầu'
            WHEN tkqht.KetQuaDanhGia_VI IN (N'Chưa đạt', N'Not Meeting Requirements', N'Not Meeting Requirements/Chưa đạt', N'Not Meeting Requirements/ Chưa đạt') 
                THEN N'Not Meeting Requirements/Chưa đạt'
            ELSE N'Không xác định'
        END,
        tbdct.ThuTuNhom;

    -- Bổ sung dữ liệu mặc định nếu thiếu
    INSERT INTO #KetQuaGoc (NhomID, TenNhom, MaCotDiem, KetQuaDanhGia_VI, ThuTuNhom)
    SELECT DISTINCT 
        NhomID,
        TenNhom,
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
            WHERE NhomID = g.NhomID 
              AND MaCotDiem = d.MaCotDiem 
              AND KetQuaDanhGia_VI = d.KetQuaDanhGia_VI
        );

    -- Tính tỷ lệ
    DECLARE @TongSoLuong INT;
    SELECT @TongSoLuong = SUM(SoLuong) FROM #KetQuaGoc;

    IF @TongSoLuong > 0
    BEGIN
        UPDATE #KetQuaGoc
        SET TyLe = ROUND(CAST(SoLuong AS DECIMAL(10,2)) * 100.0 / TongSoLuongTheoNhom, 2)
        FROM #KetQuaGoc AS KG
        CROSS APPLY (
            SELECT SUM(SoLuong) AS TongSoLuongTheoNhom
            FROM #KetQuaGoc
            WHERE NhomID = KG.NhomID AND MaCotDiem = KG.MaCotDiem
        ) AS T;
    END;

    -- Trả về kết quả
    SELECT 
        NhomID,
        TenNhom,
        MaCotDiem,
        KetQuaDanhGia_VI,
        SoLuong,
        TyLe,
        ThuTuNhom
    FROM #KetQuaGoc
    ORDER BY 
        TenNhom,
        ThuTuNhom;

    -- Dọn dẹp bảng tạm
    DROP TABLE #KetQuaGoc;
    DROP TABLE #DuLieuMacDinh;
END;
