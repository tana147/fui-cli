
-- dbo.spAPI_DashboardDiem_Mean_IELTS_Get 2024, 10, 76, 1; -- Học kỳ 1
-- dbo.spAPI_DashboardDiem_Mean_IELTS_Get 2024, 10, 76, 2; -- Học kỳ 2
CREATE PROCEDURE [dbo].[spAPI_DashboardDiem_Mean_IELTS_Get]
    @NienKhoa INT = 2024,
    @KhoiID   INT,
    @MonHocID INT,
    @HocKy    INT -- thêm học kỳ
AS
BEGIN
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

    ;WITH DataWithRanks AS
    (
        SELECT 
            tn.NhomID,
            tn.TenNhom,
            tmh.MonHocName,
            tmh.MonHocCode,
            tbdct.MaCotDiem,
            TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) AS KetQuaDanhGia,
            ROW_NUMBER() OVER (PARTITION BY tn.NhomID, tbdct.MaCotDiem 
                               ORDER BY TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))) AS RowNum,
            COUNT(*) OVER (PARTITION BY tn.NhomID, tbdct.MaCotDiem) AS TotalRows
        FROM
            dbo.tblKetQuaHocTap tkqht
            INNER JOIN dbo.tblNhom tn ON tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0
            INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
            INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
            INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        WHERE
            tkqht.NienKhoa = @NienKhoa
            AND tn.KhoiID = @KhoiID
            AND tmh.MonHocID = @MonHocID
            AND tbdct.MaCotDiem IN (@MidCot, @FinalCot)
            AND ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
			AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 2
            AND tkqht.Enable = 1
    )
    SELECT 
        NhomID,
        TenNhom,
        MonHocName,
        MonHocCode,
        MAX(CASE
            WHEN MaCotDiem = @MidCot AND TotalRows % 2 = 1 AND RowNum = (TotalRows + 1) / 2 THEN KetQuaDanhGia
            WHEN MaCotDiem = @MidCot AND TotalRows % 2 = 0 AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1) THEN KetQuaDanhGia
            ELSE NULL
        END) AS DiemGiua,
        MAX(CASE
            WHEN MaCotDiem = @FinalCot AND TotalRows % 2 = 1 AND RowNum = (TotalRows + 1) / 2 THEN KetQuaDanhGia
            WHEN MaCotDiem = @FinalCot AND TotalRows % 2 = 0 AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1) THEN KetQuaDanhGia
            ELSE NULL
        END) AS DiemCuoi
    FROM 
        DataWithRanks
    GROUP BY
        NhomID,
        TenNhom,
        MonHocName,
        MonHocCode
    ORDER BY
        NhomID;
END
