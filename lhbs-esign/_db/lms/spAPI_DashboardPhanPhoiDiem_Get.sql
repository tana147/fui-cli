--{
--    "NienKhoa": 2024,
--    "KhoiID": 10,
--    "MonHocID": 76,
--    "MaCotDiem": "S2_Final_IELTS_Band_Conv"
--}
-- [dbo].[spAPI_DashboardPhanPhoiDiem_Get] 2024, 12, 76, 'S2_Final_IELTS_Band_Conv'
CREATE PROCEDURE [dbo].[spAPI_DashboardPhanPhoiDiem_Get]
    @NienKhoa  INT
  , @KhoiID    INT
  , @MonHocID  INT
  , @MaCotDiem NVARCHAR(MAX) -- Chuỗi các MaCotDiem, phân tách bằng dấu phẩy
AS
BEGIN
    SET NOCOUNT ON;

    -- Tách chuỗi MaCotDiem thành bảng tạm
    DECLARE @MaCotDiemTable TABLE
    (
        MaCotDiem NVARCHAR(50)
    );
    INSERT INTO @MaCotDiemTable
    (
        MaCotDiem
    )
    SELECT LTRIM(RTRIM(value)) -- Sử dụng LTRIM và RTRIM thay thế TRIM
    FROM
           STRING_SPLIT(@MaCotDiem, ',');

    -- -- Các CTE
    -- WITH DiemTrungBinh AS (
    --     SELECT 
    --         tl.LopID,
    --         tl.TenLop,
    --         tmh.MonHocName,
    --         tmh.MonHocCode,
    --         tbdct.MaCotDiem,
    --         CASE 
    --             WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
    --                  AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN 
    --                 CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
    --             ELSE NULL
    --         END AS Diem,
    --         tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    --     FROM 
    --         dbo.tblKetQuaHocTap tkqht
    --     INNER JOIN 
    --         dbo.tblLop tl ON tl.LopID = tkqht.LopID
    --     INNER JOIN 
    --         dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    --     INNER JOIN 
    --         dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
    --     INNER JOIN 
    --         dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
    --     INNER JOIN 
    --         @MaCotDiemTable mcd ON tbdct.MaCotDiem = mcd.MaCotDiem
    --     WHERE 
    --         tkqht.NienKhoa = @NienKhoa
    --         AND tl.KhoiID = @KhoiID
    --         AND tmh.MonHocID = @MonHocID
    --and TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
    -- ),
    -- PhanPhoDiem AS (
    --     SELECT 
    --         MaCotDiem,
    --         CASE 
    --             WHEN Diem IS NULL OR Diem < 0 THEN N'Không hợp lệ'
    --             WHEN Diem >= 0 AND Diem < 0.5 THEN '0.0 - 0.5'
    --             WHEN Diem >= 0.5 AND Diem < 1.0 THEN '0.5 - 1.0'
    --             WHEN Diem >= 1.0 AND Diem < 1.5 THEN '1.0 - 1.5'
    --             WHEN Diem >= 1.5 AND Diem < 2.0 THEN '1.5 - 2.0'
    --             WHEN Diem >= 2.0 AND Diem < 2.5 THEN '2.0 - 2.5'
    --             WHEN Diem >= 2.5 AND Diem < 3.0 THEN '2.5 - 3.0'
    --             WHEN Diem >= 3.0 AND Diem < 3.5 THEN '3.0 - 3.5'
    --             WHEN Diem >= 3.5 AND Diem < 4.0 THEN '3.5 - 4.0'
    --             WHEN Diem >= 4.0 AND Diem < 4.5 THEN '4.0 - 4.5'
    --             WHEN Diem >= 4.5 AND Diem < 5.0 THEN '4.5 - 5.0'
    --             WHEN Diem >= 5.0 AND Diem < 5.5 THEN '5.0 - 5.5'
    --             WHEN Diem >= 5.5 AND Diem < 6.0 THEN '5.5 - 6.0'
    --             WHEN Diem >= 6.0 AND Diem < 6.5 THEN '6.0 - 6.5'
    --             WHEN Diem >= 6.5 AND Diem < 7.0 THEN '6.5 - 7.0'
    --             WHEN Diem >= 7.0 AND Diem < 7.5 THEN '7.0 - 7.5'
    --             WHEN Diem >= 7.5 AND Diem < 8.0 THEN '7.5 - 8.0'
    --             WHEN Diem >= 8.0 AND Diem < 8.5 THEN '8.0 - 8.5'
    --             WHEN Diem >= 8.5 AND Diem < 9.0 THEN '8.5 - 9.0'
    --             WHEN Diem >= 9.0 AND Diem < 9.5 THEN '9.0 - 9.5'
    --             WHEN Diem >= 9.5 AND Diem <= 10 THEN '9.5 - 10.0'
    --         END AS PhoDiem,
    --         ThuTuCotDiem -- Lấy thêm thứ tự cột điểm
    --     FROM 
    --         DiemTrungBinh

    -- ),
    -- TanSuatPhoDiem AS (
    --     SELECT 
    --         MaCotDiem,
    --         PhoDiem,
    --         COUNT(*) AS TanSuat,
    --         MAX(ThuTuCotDiem) AS ThuTuCotDiem -- Lấy thứ tự cột điểm lớn nhất để phục vụ sắp xếp
    --     FROM 
    --         PhanPhoDiem 
    --     GROUP BY 
    --         MaCotDiem, PhoDiem
    -- )
    -- -- Kết quả cuối cùng
    -- SELECT 
    --     MaCotDiem,
    --     PhoDiem,
    --     TanSuat,
    --     ThuTuCotDiem
    -- FROM 
    --     TanSuatPhoDiem
    -- ORDER BY 
    --     ThuTuCotDiem, -- Sắp xếp theo thứ tự cột điểm
    --     CASE 
    --         WHEN PhoDiem = N'Không hợp lệ' THEN 1 ELSE 0 END, 
    --     CASE 
    --         WHEN PhoDiem = N'Không hợp lệ' THEN NULL
    --         ELSE CAST(LEFT(PhoDiem, CHARINDEX(' ', PhoDiem) - 1) AS FLOAT)
    --     END;

    --data để vẽ KDE
    SELECT tl.LopID
         , tl.TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
                                                    AND tl.KhoiID          = @KhoiID
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    --ORDER BY
    --       Diem;
	UNION 
	 SELECT tl.NhomID as LopID
         , tl.TenNhom as TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblNhom                  tl ON tl.NhomID           = tkqht.LopID
                                                    AND tl.KhoiID          = @KhoiID
													and tl.IsNhomLMS_GiaoBai = 0
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    ORDER BY
           Diem;



    DECLARE @CapID INT;
    IF @KhoiID IN (1, 2, 3, 4, 5)
    BEGIN
        SET @CapID = 1;
    END;
    ELSE IF @KhoiID IN (6, 7, 8, 9)
    BEGIN
        SET @CapID = 2;
    END;
    ELSE
    BEGIN
        SET @CapID = 3;
    END;

    SELECT tl.KhoiID
         , N'Khối ' + CAST(tl.KhoiID AS VARCHAR) AS TenKhoi
         , tl.LopID
         , tl.TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten                 AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblLop                  tl ON tl.LopID           = tkqht.LopID AND tl.NienKhoa = @NienKhoa
                                                    AND tl.CapID           = @CapID
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0 
      AND  tkqht.Enable                                       = 1

	UNION
	SELECT tl.KhoiID
         , N'Khối ' + CAST(tl.KhoiID AS VARCHAR) AS TenKhoi
         , tl.NhomID as LopID
         , tl.TenNhom as TenLop
         , hs.HocSinhID
         , hs.Ho + N' ' + hs.Ten                 AS HoTen
         , tmh.MonHocName
         , tmh.MonHocCode
         , tbdct.MaCotDiem
         , CASE
                WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2))
                ELSE NULL
           END                                   AS Diem
         , tbdct.ThuTuCotDiem -- Thứ tự cột điểm
    FROM
           dbo.tblKetQuaHocTap                    tkqht
           INNER JOIN dbo.tblNhom                  tl ON tl.NhomID           = tkqht.LopID
                                                    AND tl.CapID           = @CapID
           INNER JOIN dbo.tblHocSinh              hs ON hs.HocSinhID       = tkqht.HocSinhID
           INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
           INNER JOIN dbo.tblMonHocLop            tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
           INNER JOIN dbo.tblMonHoc               tmh ON tmh.MonHocID      = @MonHocID
           INNER JOIN @MaCotDiemTable             mcd ON tbdct.MaCotDiem   = mcd.MaCotDiem
    WHERE
           tkqht.NienKhoa                                    = @NienKhoa
      AND  TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
      AND  tkqht.Enable                                       = 1
    ORDER BY
           TenLop
         , Diem;
END;