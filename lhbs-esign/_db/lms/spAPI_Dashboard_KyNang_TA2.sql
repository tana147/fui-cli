
CREATE PROC [dbo].[spAPI_Dashboard_KyNang_TA2]
@NienKhoa INT,
@CapID INT,
@Semester VARCHAR(20)
AS
BEGIN
    DECLARE @GK NVARCHAR(20) = N'';
    DECLARE @CK NVARCHAR(20) = N'';
    
    IF @Semester = 'HK1'
    BEGIN
        SET @GK = N'S1_Mid_TA2';
        SET @CK = N'S1_Final_TA2';
    END;
    ELSE IF @Semester = 'HK2'
    BEGIN
        SET @GK = N'S2_Mid_TA2';
        SET @CK = N'S2_Final_TA2';
    END;

    -- First result set: Mid-term (GK) with Grouping
    SELECT 
        -- Add grouping logic based on class name pattern
        CASE 
            WHEN n.TenNhom LIKE '%-10AV1' OR n.TenNhom LIKE '%-10AV2' THEN '10AV1,2'
            WHEN n.TenNhom LIKE '%-10AV3' OR n.TenNhom LIKE '%-10AV4' THEN '10AV3,4'
            WHEN n.TenNhom LIKE '%-10AV5' THEN '10AV5'
            WHEN n.TenNhom LIKE '%-11AV1' OR n.TenNhom LIKE '%-11AV2' THEN '11AV1,2'
            WHEN n.TenNhom LIKE '%-11AV3' OR n.TenNhom LIKE '%-11AV4' THEN '11AV3,4'
            WHEN n.TenNhom LIKE '%-11AV5' OR n.TenNhom LIKE '%-11AV6' THEN '11AV5,6'
            WHEN n.TenNhom LIKE '%-12AV1' OR n.TenNhom LIKE '%-12AV2' THEN '12AV1,2'
            WHEN n.TenNhom LIKE '%-12AV3' OR n.TenNhom LIKE '%-12AV4' THEN '12AV3,4'
            WHEN n.TenNhom LIKE '%-12AV5' OR n.TenNhom LIKE '%-12AV6' THEN '12AV5,6'
            ELSE n.TenNhom
        END AS TenNhom,
        
        COUNT(DISTINCT hsn.HocSinhID) AS TongHocSinh,
        
        -- Listening
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) AS Nghe_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) AS Nghe_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Nghe_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_CD_PCT,
        
        -- Reading
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) AS Doc_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) AS Doc_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Doc_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_CD_PCT,
        
        -- Speaking
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) AS Noi_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) AS Noi_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Noi_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_CD_PCT,
        
        -- Writing
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) AS Viet_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) AS Viet_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Viet_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_CD_PCT,
        
        -- Average
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) AS TrungBinh_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) AS TrungBinh_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @GK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS TrungBinh_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding requirements/Vượt đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @GK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_CD_PCT
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = kqht.HocSinhID AND hsn.NhomID = kqht.LopID AND hsn.Enable = 1
    INNER JOIN dbo.tblNhom n ON n.NhomID = hsn.NhomID AND n.NhomID = kqht.LopID AND n.Enable = 1 AND n.NienKhoa = @NienKhoa
    INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID AND ct.Enable = 1
        AND ct.MaCotDiem LIKE '%TA2%'
        AND ct.MaNhomCotDiem = @GK
    INNER JOIN dbo.tblMonHocLop mhl ON mhl.Enable = 1 AND mhl.MonHocLopID = kqht.MonHocLopID AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocID = 76
    WHERE kqht.NienKhoa = @NienKhoa AND kqht.Enable = 1 AND ct.MaCotDiem NOT LIKE '%Point%'
    GROUP BY 
        CASE 
            WHEN n.TenNhom LIKE '%-10AV1' OR n.TenNhom LIKE '%-10AV2' THEN '10AV1,2'
            WHEN n.TenNhom LIKE '%-10AV3' OR n.TenNhom LIKE '%-10AV4' THEN '10AV3,4'
            WHEN n.TenNhom LIKE '%-10AV5' THEN '10AV5'
            WHEN n.TenNhom LIKE '%-11AV1' OR n.TenNhom LIKE '%-11AV2' THEN '11AV1,2'
            WHEN n.TenNhom LIKE '%-11AV3' OR n.TenNhom LIKE '%-11AV4' THEN '11AV3,4'
            WHEN n.TenNhom LIKE '%-11AV5' OR n.TenNhom LIKE '%-11AV6' THEN '11AV5,6'
            WHEN n.TenNhom LIKE '%-12AV1' OR n.TenNhom LIKE '%-12AV2' THEN '12AV1,2'
            WHEN n.TenNhom LIKE '%-12AV3' OR n.TenNhom LIKE '%-12AV4' THEN '12AV3,4'
            WHEN n.TenNhom LIKE '%-12AV5' OR n.TenNhom LIKE '%-12AV6' THEN '12AV5,6'
            ELSE n.TenNhom
        END
    ORDER BY TenNhom;

    -- Second result set: Final (CK) with Grouping
    SELECT 
        CASE 
            WHEN n.TenNhom LIKE '%-10AV1' OR n.TenNhom LIKE '%-10AV2' THEN '10AV1,2'
            WHEN n.TenNhom LIKE '%-10AV3' OR n.TenNhom LIKE '%-10AV4' THEN '10AV3,4'
            WHEN n.TenNhom LIKE '%-10AV5' THEN '10AV5'
            WHEN n.TenNhom LIKE '%-11AV1' OR n.TenNhom LIKE '%-11AV2' THEN '11AV1,2'
            WHEN n.TenNhom LIKE '%-11AV3' OR n.TenNhom LIKE '%-11AV4' THEN '11AV3,4'
            WHEN n.TenNhom LIKE '%-11AV5' OR n.TenNhom LIKE '%-11AV6' THEN '11AV5,6'
            WHEN n.TenNhom LIKE '%-12AV1' OR n.TenNhom LIKE '%-12AV2' THEN '12AV1,2'
            WHEN n.TenNhom LIKE '%-12AV3' OR n.TenNhom LIKE '%-12AV4' THEN '12AV3,4'
            WHEN n.TenNhom LIKE '%-12AV5' OR n.TenNhom LIKE '%-12AV6' THEN '12AV5,6'
            ELSE n.TenNhom
        END AS TenNhom,
        
        COUNT(DISTINCT hsn.HocSinhID) AS TongHocSinh,
        
        -- Listening
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS Nghe_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS Nghe_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Nghe_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Listening_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Nghe_CD_PCT,
        
        -- Reading
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS Doc_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS Doc_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Doc_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Reading_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Doc_CD_PCT,
        
        -- Speaking
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS Noi_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS Noi_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Noi_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Speaking_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Noi_CD_PCT,
        
        -- Writing
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS Viet_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS Viet_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS Viet_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Writing_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS Viet_CD_PCT,
        
        -- Average
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) AS TrungBinh_VYC,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) AS TrungBinh_D,
        SUM(CASE WHEN ct.MaCotDiem LIKE @CK+'_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) AS TrungBinh_CD,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Exceeding Requirements/Vượt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_VYC_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Meeting Requirements/Đạt yêu cầu' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_D_PCT,
        CAST(100.0 * SUM(CASE WHEN ct.MaCotDiem LIKE @CK + '_Avg_Conv' AND kqht.KetQuaDanhGia_VI = N'Not Meeting Requirements/Chưa đạt' THEN 1 ELSE 0 END) / COUNT(DISTINCT hsn.HocSinhID) AS DECIMAL(5,2)) AS TrungBinh_CD_PCT
    FROM dbo.tblKetQuaHocTap kqht
    INNER JOIN dbo.tblHocSinhNhom hsn ON hsn.HocSinhID = kqht.HocSinhID AND hsn.NhomID = kqht.LopID AND hsn.Enable = 1
    INNER JOIN dbo.tblNhom n ON n.NhomID = hsn.NhomID AND n.NhomID = kqht.LopID AND n.Enable = 1 AND n.NienKhoa = @NienKhoa
    INNER JOIN dbo.TemplateBangDiemChiTiet ct ON ct.CotDiemID = kqht.CotDiemID AND ct.Enable = 1
        AND ct.MaCotDiem LIKE '%TA2%'
        AND ct.MaNhomCotDiem = @CK
    INNER JOIN dbo.tblMonHocLop mhl ON mhl.Enable = 1 AND mhl.MonHocLopID = kqht.MonHocLopID AND mhl.NienKhoa = @NienKhoa
        AND mhl.MonHocID = 76
    WHERE kqht.NienKhoa = @NienKhoa AND kqht.Enable = 1 AND ct.MaCotDiem NOT LIKE '%Point%'
     GROUP BY 
        CASE 
            WHEN n.TenNhom LIKE '%-10AV1' OR n.TenNhom LIKE '%-10AV2' THEN '10AV1,2'
            WHEN n.TenNhom LIKE '%-10AV3' OR n.TenNhom LIKE '%-10AV4' THEN '10AV3,4'
            WHEN n.TenNhom LIKE '%-10AV5' THEN '10AV5'
            WHEN n.TenNhom LIKE '%-11AV1' OR n.TenNhom LIKE '%-11AV2' THEN '11AV1,2'
            WHEN n.TenNhom LIKE '%-11AV3' OR n.TenNhom LIKE '%-11AV4' THEN '11AV3,4'
            WHEN n.TenNhom LIKE '%-11AV5' OR n.TenNhom LIKE '%-11AV6' THEN '11AV5,6'
            WHEN n.TenNhom LIKE '%-12AV1' OR n.TenNhom LIKE '%-12AV2' THEN '12AV1,2'
            WHEN n.TenNhom LIKE '%-12AV3' OR n.TenNhom LIKE '%-12AV4' THEN '12AV3,4'
            WHEN n.TenNhom LIKE '%-12AV5' OR n.TenNhom LIKE '%-12AV6' THEN '12AV5,6'
            ELSE n.TenNhom
        END
    ORDER BY TenNhom;
	end