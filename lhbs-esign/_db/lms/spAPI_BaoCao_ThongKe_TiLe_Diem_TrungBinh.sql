
CREATE PROC [dbo].[spAPI_BaoCao_ThongKe_TiLe_Diem_TrungBinh]
    @Semester VARCHAR(50),
    @CapID    INT,
    @NienKhoa INT
AS
BEGIN
    -- CTE chung để tính toán điểm số
    ;WITH DiemCalculation AS (
        SELECT 
            kqht.HocSinhID,
            kqht.LopID,
            mhl.LopNhomID,
            mh.MonHocID,
            mh.TenMonHoc_HienThi,
            kqht.KetQuaDanhGia_VI,
            CASE 
                WHEN TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) >= 0 
                     AND TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) < 5 THEN 1 
                ELSE 0 
            END AS Diem_0_5,
            CASE 
                WHEN TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) >= 5 
                     AND TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) < 6.5 THEN 1 
                ELSE 0 
            END AS Diem_5_6_5,
            CASE 
                WHEN TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) >= 6.5 
                     AND TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) < 8 THEN 1 
                ELSE 0 
            END AS Diem_6_5_8,
            CASE 
                WHEN TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) >= 8 
                     AND TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) <= 10 THEN 1 
                ELSE 0 
            END AS Diem_8_10,
            CASE 
                WHEN TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) >= 5 
                     AND TRY_CAST(kqht.KetQuaDanhGia_VI AS FLOAT) <= 10 THEN 1 
                ELSE 0 
            END AS Diem_5_10,
            CASE WHEN kqht.KetQuaDanhGia_VI = N'CĐ' THEN 1 ELSE 0 END AS Diem_CD,
            CASE WHEN kqht.KetQuaDanhGia_VI = N'Đ' THEN 1 ELSE 0 END AS Diem_D
        FROM dbo.tblKetQuaHocTap kqht
        INNER JOIN dbo.TemplateBangDiemChiTiet ct 
            ON ct.CotDiemID = kqht.CotDiemID
            AND ct.Enable = 1
            AND ct.MaCotDiem = 'DiemTB_' + @Semester
        INNER JOIN dbo.tblMonHocLop mhl 
            ON mhl.MonHocLopID = kqht.MonHocLopID
            AND mhl.Enable = 1
            AND mhl.NienKhoa = @NienKhoa
        INNER JOIN dbo.tblMonHoc mh 
            ON mh.MonHocID = mhl.MonHocID
            AND mh.Enable = 1
            AND mh.CapID = @CapID
        WHERE kqht.Enable = 1
          AND kqht.NienKhoa = @NienKhoa
    )
    
    -- Xử lý cho CapID = 2 (Lớp)
    SELECT 
        l.TenLop,
        dc.TenMonHoc_HienThi,
        dc.MonHocID,
        COUNT(DISTINCT dc.HocSinhID) AS TongSoHocSinh,
        SUM(dc.Diem_0_5) AS Diem_0_5,
        SUM(dc.Diem_5_6_5) AS Diem_5_6_5,
        SUM(dc.Diem_6_5_8) AS Diem_6_5_8,
        SUM(dc.Diem_8_10) AS Diem_8_10,
        SUM(dc.Diem_5_10) AS Diem_5_10,
        NULLIF(SUM(dc.Diem_CD), 0) AS Diem_CD,
        NULLIF(SUM(dc.Diem_D), 0) AS Diem_D
    FROM DiemCalculation dc
    INNER JOIN dbo.tblLop l 
        ON l.LopID = dc.LopNhomID
        AND l.LopID = dc.LopID
        AND l.NienKhoa = @NienKhoa
        AND l.CapID = @CapID
        AND l.Enable = 1
    WHERE @CapID = 2
    GROUP BY l.TenLop, dc.TenMonHoc_HienThi, dc.MonHocID
    
    UNION ALL
    
    -- Xử lý cho CapID = 3 - Lớp thường
    SELECT 
        l.TenLop,
        dc.TenMonHoc_HienThi,
        dc.MonHocID,
        COUNT(DISTINCT dc.HocSinhID) AS TongSoHocSinh,
        SUM(dc.Diem_0_5) AS Diem_0_5,
        SUM(dc.Diem_5_6_5) AS Diem_5_6_5,
        SUM(dc.Diem_6_5_8) AS Diem_6_5_8,
        SUM(dc.Diem_8_10) AS Diem_8_10,
        SUM(dc.Diem_5_10) AS Diem_5_10,
        NULLIF(SUM(dc.Diem_CD), 0) AS Diem_CD,
        NULLIF(SUM(dc.Diem_D), 0) AS Diem_D
    FROM DiemCalculation dc
    INNER JOIN dbo.tblLop l 
        ON l.LopID = dc.LopNhomID
        AND l.LopID = dc.LopID
        AND l.NienKhoa = @NienKhoa
        AND l.CapID = @CapID
        AND l.Enable = 1
    WHERE @CapID = 3
    GROUP BY l.TenLop, dc.TenMonHoc_HienThi, dc.MonHocID
    
    UNION ALL
    
    -- Xử lý cho CapID = 3 - Nhóm
    SELECT 
        l.TenLop,
        dc.TenMonHoc_HienThi,
        dc.MonHocID,
        COUNT(DISTINCT dc.HocSinhID) AS TongSoHocSinh,
        SUM(dc.Diem_0_5) AS Diem_0_5,
        SUM(dc.Diem_5_6_5) AS Diem_5_6_5,
        SUM(dc.Diem_6_5_8) AS Diem_6_5_8,
        SUM(dc.Diem_8_10) AS Diem_8_10,
        SUM(dc.Diem_5_10) AS Diem_5_10,
        NULLIF(SUM(dc.Diem_CD), 0) AS Diem_CD,
        NULLIF(SUM(dc.Diem_D), 0) AS Diem_D
    FROM DiemCalculation dc
    INNER JOIN dbo.tblNhom n 
        ON n.NhomID = dc.LopNhomID
        AND n.NhomID = dc.LopID
        AND n.NienKhoa = @NienKhoa
        AND n.CapID = @CapID
        AND n.Enable = 1
    INNER JOIN dbo.tblHocSinhNhom hsn 
        ON hsn.NhomID = dc.LopID
        AND hsn.HocSinhID = dc.HocSinhID
        AND hsn.Enable = 1
    INNER JOIN dbo.tblLop l 
        ON l.LopID = hsn.LopID 
        AND l.Enable = 1 
        AND l.NienKhoa = @NienKhoa
    WHERE @CapID = 3
    GROUP BY l.TenLop, dc.TenMonHoc_HienThi, dc.MonHocID
    
    ORDER BY TenLop, TenMonHoc_HienThi;
END
