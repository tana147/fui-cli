
-- [spAPI_DashboardTiLeDat_Growth_GiuaKy_CuoiKi_Get] 3, 76, 2024
CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Growth_GiuaKy_CuoiKi_Get]
    @CapID INT,
    @MonHocID INT,
    @NienKhoa NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tạo bảng tạm để lưu kết quả trung gian
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
        MAX(CASE 
            WHEN tbdct.MaCotDiem = 'S1_Mid_Total_Point' 
            THEN CONVERT(DECIMAL(10, 2), tkqht.KetQuaDanhGia_VI)
            ELSE NULL
        END) AS DiemGK_HK1,
        MAX(CASE 
            WHEN tbdct.MaCotDiem = 'S1_Final_Total_Point' 
            THEN CONVERT(DECIMAL(10, 2), tkqht.KetQuaDanhGia_VI)
            ELSE NULL
        END) AS DiemCK_HK1
    FROM 
        dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.tblHocSinh hs ON tkqht.HocSinhID = hs.HocSinhID
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        LEFT JOIN dbo.tblLop tl ON (@CapID != 3 AND tl.LopID = tkqht.LopID) AND tl.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom tn ON (@CapID = 3 AND tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0)
    WHERE 
        tbdct.MaCotDiem IN ('S1_Mid_Total_Point', 'S1_Final_Total_Point')
        AND tkqht.NienKhoa = @NienKhoa
        AND tmh.MonHocID = @MonHocID
        AND tkqht.Enable = 1
    GROUP BY 
        CASE WHEN @CapID = 3 THEN tn.KhoiID ELSE tl.KhoiID END,
        CASE WHEN @CapID = 3 THEN tn.NhomID ELSE tl.LopID END,
        CASE WHEN @CapID = 3 THEN tn.TenNhom ELSE tl.TenLop END,
        hs.HocSinhID;

    -- Đếm tổng số học sinh và số học sinh có điểm cuối kỳ cao hơn điểm giữa kỳ
    DECLARE @TongSoHocSinh INT;
    DECLARE @SoHocSinhCaoHon INT;

    -- Tổng số học sinh
    SELECT @TongSoHocSinh = COUNT(*) FROM @KetQuaGoc;

    -- Số học sinh có điểm cuối kỳ cao hơn giữa kỳ
    SELECT @SoHocSinhCaoHon = COUNT(*) 
    FROM @KetQuaGoc
    WHERE DiemCK_HK1 > DiemGK_HK1;

    -- Tính tỷ lệ phần trăm
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

    -- Tính tổng số học sinh, số học sinh có điểm cuối kỳ cao hơn giữa kỳ và tỷ lệ cho từng khối
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

    -- Tính tổng số học sinh theo từng lớp
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
