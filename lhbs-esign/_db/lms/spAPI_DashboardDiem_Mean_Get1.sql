-- [spAPI_DashboardDiem_Mean_Get1] 2024, 10,76,2

CREATE PROCEDURE [dbo].[spAPI_DashboardDiem_Mean_Get1]
    @NienKhoa INT,
    @KhoiID   INT,
    @MonHocID INT,
     @HocKy    INT
AS
BEGIN;
    -- Khai báo bảng chứa mã cột điểm theo học kỳ
    DECLARE @CotDiem TABLE (
        MaCotDiem NVARCHAR(50),
        CotAlias NVARCHAR(50)
    );

    -- Thêm mã điểm tương ứng với học kỳ
    IF @HocKy = 1
    BEGIN
        INSERT INTO @CotDiem VALUES
        ('S1_Mid_Total_Point', 'DiemGiua'),
        ('S1_Final_Total_Point', 'DiemCuoi'),
        ('DiemTB_HK1', 'DiemTB');
    END
    ELSE IF @HocKy = 2
    BEGIN
        INSERT INTO @CotDiem VALUES
        ('S2_Mid_Total_Point', 'DiemGiua'),
        ('S2_Final_Total_Point', 'DiemCuoi'),
        ('DiemTB_HK2', 'DiemTB');
    END;

    WITH DataWithRanks AS
    (
        SELECT 
              CASE WHEN @KhoiID IN (10, 11, 12) THEN tn.NhomID ELSE tl.LopID END AS LopID,
              CASE WHEN @KhoiID IN (10, 11, 12) THEN tn.TenNhom ELSE tl.TenLop END AS TenLop,
              tmh.MonHocName,
              tmh.MonHocCode,
              tbdct.MaCotDiem,
              cd.CotAlias,
              CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) AS KetQuaDanhGia,
              ROW_NUMBER() OVER (
                  PARTITION BY 
                      CASE WHEN @KhoiID IN (10, 11, 12) THEN tn.NhomID ELSE tl.LopID END,
                      tbdct.MaCotDiem
                  ORDER BY 
                      CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2))
              ) AS RowNum,
              COUNT(*) OVER (
                  PARTITION BY 
                      CASE WHEN @KhoiID IN (10, 11, 12) THEN tn.NhomID ELSE tl.LopID END,
                      tbdct.MaCotDiem
              ) AS TotalRows
        FROM dbo.tblKetQuaHocTap tkqht
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
        INNER JOIN @CotDiem cd ON cd.MaCotDiem = tbdct.MaCotDiem
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        LEFT JOIN dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.NienKhoa = @NienKhoa
        LEFT JOIN dbo.tblNhom tn ON tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0
        WHERE
            tkqht.NienKhoa = @NienKhoa
            AND tmh.MonHocID = @MonHocID
            AND ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
            AND tkqht.Enable = 1
            AND (
                (@KhoiID NOT IN (10, 11, 12) AND tl.KhoiID = @KhoiID) OR
                (@KhoiID IN (10, 11, 12) AND tn.KhoiID = @KhoiID)
            )
    )
    SELECT 
          LopID,
          TenLop,
          MonHocName,
          MonHocCode,
          MAX(CASE WHEN CotAlias = 'DiemGiua' AND TotalRows % 2 = 1 AND RowNum = (TotalRows + 1) / 2 
                   THEN KetQuaDanhGia
                   WHEN CotAlias = 'DiemGiua' AND TotalRows % 2 = 0 AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1)
                   THEN KetQuaDanhGia
              END) AS DiemGiua,

          MAX(CASE WHEN CotAlias = 'DiemCuoi' AND TotalRows % 2 = 1 AND RowNum = (TotalRows + 1) / 2 
                   THEN KetQuaDanhGia
                   WHEN CotAlias = 'DiemCuoi' AND TotalRows % 2 = 0 AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1)
                   THEN KetQuaDanhGia
              END) AS DiemCuoi,

          MAX(CASE WHEN CotAlias = 'DiemTB' AND TotalRows % 2 = 1 AND RowNum = (TotalRows + 1) / 2 
                   THEN KetQuaDanhGia
                   WHEN CotAlias = 'DiemTB' AND TotalRows % 2 = 0 AND RowNum IN (TotalRows / 2, TotalRows / 2 + 1)
                   THEN KetQuaDanhGia
              END) AS DiemTB
    FROM DataWithRanks
    GROUP BY 
          LopID,
          TenLop,
          MonHocName,
          MonHocCode
    ORDER BY 
          LopID;
END;
