
-- [dbo].[spAPI_DashboardTiLeDat_Get] 6, NULL,'S1_Final_Total_Point', 2024
CREATE PROCEDURE [dbo].[spAPI_DashboardTiLeDat_Get]
    @KhoiID INT,
    @LopID INT,
    @MaCotDiem NVARCHAR(50),
    @NienKhoa NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Bảng tạm để lưu kết quả
    CREATE TABLE #KetQuaGoc (
        KetQuaDanhGia_VI NVARCHAR(100),
        SoLuong INT,
        TyLe DECIMAL(5,2)
    );

    -- Chèn dữ liệu từ truy vấn gốc
    WITH CTE AS (
        SELECT 
            CASE 
                WHEN KetQuaDanhGia_VI IN (N'Vượt yêu cầu', N'Exceeding Requirements', N'Exceeding Requirements/ Vượt yêu cầu') 
                THEN N'Exceeding Requirements/Vượt yêu cầu'
                WHEN KetQuaDanhGia_VI IN (N'Đạt yêu cầu', N'Meeting Requirements', N'Meeting Requirements/Đạt yêu cầu') 
                THEN N'Meeting Requirements/Đạt yêu cầu'
                WHEN KetQuaDanhGia_VI IN (N'Chưa đạt', N'Not Meeting Requirements', N'Not Meeting Requirements/Chưa đạt', N'Not Meeting Requirements/ Chưa đạt') 
                THEN N'Not Meeting Requirements/Chưa đạt'
                ELSE ISNULL(KetQuaDanhGia_VI, N'Không xác định')
            END AS KetQuaDanhGia_VI,
            COUNT(*) AS SoLuong
        FROM 
            (
                SELECT 
                    tkqht.HocSinhID,
                    hs.Ho + ' ' + hs.Ten AS HoTen,
                    tbdct.TenCotDiem_VI,
                    tbdct.MaCotDiem,
                    tmh.MonHocCode,
                    tmh.MonHocName,
                    tkqht.KetQuaDanhGia_VI,
                    tl.TenLop,
                    tl.LopID,
                    tl.NienKhoa
                FROM 
                    dbo.tblKetQuaHocTap tkqht
                    INNER JOIN dbo.tblHocSinh hs ON tkqht.HocSinhID = hs.HocSinhID
                    INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tkqht.CotDiemID = tbdct.CotDiemID
                    INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
                    INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
                    INNER JOIN dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.NienKhoa = tkqht.NienKhoa AND tl.NienKhoa = @NienKhoa
                WHERE 
                    tbdct.MaCotDiem = @MaCotDiem
                    AND tkqht.NienKhoa = @NienKhoa
                    AND 
                    (
                        (tl.KhoiID = @KhoiID AND @LopID IS NULL)
                        OR 
                        (tl.KhoiID = @KhoiID AND tl.LopID = @LopID)
                    )
					  AND  tkqht.Enable                      = 1
            ) AS DuLieu
        GROUP BY 
            CASE 
                WHEN KetQuaDanhGia_VI IN (N'Vượt yêu cầu', N'Exceeding Requirements', N'Exceeding Requirements/ Vượt yêu cầu') 
                THEN N'Exceeding Requirements/Vượt yêu cầu'
                WHEN KetQuaDanhGia_VI IN (N'Đạt yêu cầu', N'Meeting Requirements', N'Meeting Requirements/Đạt yêu cầu') 
                THEN N'Meeting Requirements/Đạt yêu cầu'
                WHEN KetQuaDanhGia_VI IN (N'Chưa đạt', N'Not Meeting Requirements', N'Not Meeting Requirements/Chưa đạt', N'Not Meeting Requirements/ Chưa đạt') 
                THEN N'Not Meeting Requirements/Chưa đạt'
                ELSE ISNULL(KetQuaDanhGia_VI, N'Không xác định')
            END
    )


    INSERT INTO #KetQuaGoc (KetQuaDanhGia_VI, SoLuong, TyLe)
    SELECT 
        KetQuaDanhGia_VI, 
        SUM(SoLuong) AS SoLuong, 
        ROUND(SUM(SoLuong) * 100.0 / (SELECT SUM(SoLuong) FROM CTE), 2) AS TyLe
    FROM CTE
    GROUP BY KetQuaDanhGia_VI;

    -- Thêm các danh mục còn thiếu
    ;WITH DanhMucCanThem AS (
        SELECT N'Exceeding Requirements/Vượt yêu cầu' AS KetQuaDanhGia_VI
        UNION ALL
        SELECT N'Meeting Requirements/Đạt yêu cầu'
        UNION ALL
        SELECT N'Not Meeting Requirements/Chưa đạt'
    )
    INSERT INTO #KetQuaGoc (KetQuaDanhGia_VI, SoLuong, TyLe)
    SELECT 
        DanhMucCanThem.KetQuaDanhGia_VI, 
        0 AS SoLuong, 
        0.00 AS TyLe
    FROM DanhMucCanThem
    WHERE DanhMucCanThem.KetQuaDanhGia_VI NOT IN (SELECT KetQuaDanhGia_VI FROM #KetQuaGoc);

    -- Điều chỉnh tỷ lệ để tổng bằng 100%
    DECLARE @TongTyLe DECIMAL(5,2);
    SELECT @TongTyLe = SUM(TyLe) FROM #KetQuaGoc;

    IF @TongTyLe > 0 AND @TongTyLe != 100.00
    BEGIN
        UPDATE #KetQuaGoc
        SET TyLe = ROUND(TyLe * (100.0 / @TongTyLe), 2)
        WHERE SoLuong > 0;
    END

    -- Trả về kết quả
    SELECT 
        KetQuaDanhGia_VI,
        SoLuong,
        TyLe AS TyLeChinhXac
    FROM #KetQuaGoc
    ORDER BY 
        CASE KetQuaDanhGia_VI
            WHEN N'Exceeding Requirements/Vượt yêu cầu' THEN 1
            WHEN N'Meeting Requirements/Đạt yêu cầu' THEN 2
            WHEN N'Not Meeting Requirements/Chưa đạt' THEN 3
            ELSE 4
        END;

    -- Dọn dẹp bảng tạm
    DROP TABLE #KetQuaGoc;
END;
