CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Growth_GiuaKy_CuoiKi_Get1]
    @CapID INT,
    @MonHocID INT,
    @NienKhoa NVARCHAR(50),
    @HocKy INT -- Thêm tham số học kỳ
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MidCot NVARCHAR(50);
    DECLARE @FinalCot NVARCHAR(50);

    -- Xác định cột điểm theo học kỳ
    IF @HocKy = 1
    BEGIN
        SET @MidCot = 'S1_Mid_Total_Point';
        SET @FinalCot = 'S1_Final_Total_Point';
    END
    ELSE IF @HocKy = 2
    BEGIN
        SET @MidCot = 'S2_Mid_Total_Point';
        SET @FinalCot = 'S2_Final_Total_Point';
    END
    ELSE
    BEGIN
        -- Nếu @HocKy không hợp lệ thì báo lỗi
        THROW 50000, 'HocKy không hợp lệ. Chỉ nhận giá trị 1 hoặc 2.', 1;
    END

    DECLARE @KetQuaGoc AS TABLE(
        KhoiID INT,
        LopID VARCHAR(9),
        TenLop NVARCHAR(255),
        HocSinhID VARCHAR(9),
        DiemGK_HK1 DECIMAL(10,2),
        DiemCK_HK1 DECIMAL(10,2)
    );

    -- Truy vấn dữ liệu thực tế và chuẩn hóa kết quả đánh giá
    INSERT INTO @KetQuaGoc (KhoiID, LopID, TenLop, HocSinhID, DiemGK_HK1, DiemCK_HK1)
    SELECT 
        CASE WHEN @CapID = 3 THEN tn.KhoiID ELSE tl.KhoiID END AS KhoiID,
        CASE WHEN @CapID = 3 THEN tn.NhomID ELSE tl.LopID END AS LopID,
        CASE WHEN @CapID = 3 THEN tn.TenNhom ELSE tl.TenLop END AS TenLop,
        hs.HocSinhID,
        MAX(CASE WHEN tbdct.MaCotDiem = @MidCot THEN TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) ELSE NULL END) AS DiemGK_HK1,
        MAX(CASE WHEN tbdct.MaCotDiem = @FinalCot THEN TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) ELSE NULL END) AS DiemCK_HK1
    FROM 
        dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh hs ON tkqht.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        LEFT JOIN dbo.tblLop tl ON (@CapID != 3 AND tl.LopID = tkqht.LopID) AND tl.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom tn ON (@CapID = 3 AND tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0)
    WHERE 
        tbdct.MaCotDiem IN (@MidCot, @FinalCot)
        AND tkqht.NienKhoa = @NienKhoa
        AND tmh.MonHocID = @MonHocID
        AND tkqht.Enable = 1
    GROUP BY 
        CASE WHEN @CapID = 3 THEN tn.KhoiID ELSE tl.KhoiID END,
        CASE WHEN @CapID = 3 THEN tn.NhomID ELSE tl.LopID END,
        CASE WHEN @CapID = 3 THEN tn.TenNhom ELSE tl.TenLop END,
        hs.HocSinhID;

    -- Đếm tổng số học sinh và số học sinh có điểm cuối kỳ cao hơn giữa kỳ
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

    -- Theo Khối
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

    -- Theo Lớp
    SELECT 
        KhoiID,
        LopID,
        TenLop,
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
        LopID,
        TenLop;

END;
