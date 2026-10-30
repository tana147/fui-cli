CREATE PROC spAPI_ThongKe_Cambridge
    @CapID INT,
    @NienKhoa INT,
    @List_LopID VARCHAR(200),
    @Semester VARCHAR(10)
AS
BEGIN
    IF @NienKhoa IS NULL
    BEGIN
        RAISERROR(N'Niên khóa là bắt buộc để xác định đúng lớp.', 16, 1)
        RETURN
    END

    -- Danh sách các phân loại chuẩn
    DECLARE @PhanLoai TABLE (DanhGiaChung NVARCHAR(50))
    INSERT INTO @PhanLoai VALUES (N'Vượt yêu cầu'), (N'Đạt'), (N'Chưa đạt')
    
    ;WITH DanhSachLop AS (
        SELECT DISTINCT
            l.LopID,
            l.TenLop
        FROM dbo.tblLop l
        WHERE l.LopID IN (SELECT value FROM STRING_SPLIT(@List_LopID, ','))
            AND l.Enable = 1 
            AND l.NienKhoa = @NienKhoa
    ),
    -- Tạo đầy đủ các tổ hợp Lớp x Phân loại
    LopPhanLoai AS (
        SELECT 
            l.LopID,
            l.TenLop,
            p.DanhGiaChung
        FROM DanhSachLop l
        CROSS JOIN @PhanLoai p
    ),
    ThongKeLop AS (
        SELECT 
            l.LopID,
            COUNT(DISTINCT bc.HocSinhID) AS SiSo
        FROM dbo.tblBaoCao_Cambridge bc
            INNER JOIN dbo.tblHocSinhLop hsl ON hsl.HocSinhID = bc.HocSinhID AND hsl.Enable = 1
			INNER JOIN dbo.tblHocSinh hs ON hs.HocSinhID = bc.HocSinhID AND hs.HocSinhID = hsl.HocSinhID AND hs.TinhTrang = 0 
            INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
        AND hsl.NienKhoa = l.NienKhoa
        WHERE l.LopID IN (SELECT value FROM STRING_SPLIT(@List_LopID, ','))
            AND bc.HocKi = @Semester
            AND bc.CapID = @CapID
        GROUP BY l.LopID
    ),
    ThongKePhanLoai AS (
        SELECT 
            l.LopID,
            bc.DanhGiaChung,
            -- Nghe - đếm số học sinh có kỹ năng này ở mức tương ứng trong nhóm phân loại
            SUM(CASE WHEN bc.NghePL = N'Chưa đạt' THEN 1 ELSE 0 END) AS Nghe_ChuaDat,
            SUM(CASE WHEN bc.NghePL = N'Đạt' THEN 1 ELSE 0 END) AS Nghe_Dat,
            SUM(CASE WHEN bc.NghePL = N'Vượt yêu cầu' THEN 1 ELSE 0 END) AS Nghe_VuotYeuCau,
            -- Đọc
            SUM(CASE WHEN bc.DocPL = N'Chưa đạt' THEN 1 ELSE 0 END) AS Doc_ChuaDat,
            SUM(CASE WHEN bc.DocPL = N'Đạt' THEN 1 ELSE 0 END) AS Doc_Dat,
            SUM(CASE WHEN bc.DocPL = N'Vượt yêu cầu' THEN 1 ELSE 0 END) AS Doc_VuotYeuCau,
            -- Viết
            SUM(CASE WHEN bc.VietPL = N'Chưa đạt' THEN 1 ELSE 0 END) AS Viet_ChuaDat,
            SUM(CASE WHEN bc.VietPL = N'Đạt' THEN 1 ELSE 0 END) AS Viet_Dat,
            SUM(CASE WHEN bc.VietPL = N'Vượt yêu cầu' THEN 1 ELSE 0 END) AS Viet_VuotYeuCau,
            -- Nói
            SUM(CASE WHEN bc.NoiPL = N'Chưa đạt' THEN 1 ELSE 0 END) AS Noi_ChuaDat,
            SUM(CASE WHEN bc.NoiPL = N'Đạt' THEN 1 ELSE 0 END) AS Noi_Dat,
            SUM(CASE WHEN bc.NoiPL = N'Vượt yêu cầu' THEN 1 ELSE 0 END) AS Noi_VuotYeuCau,
            -- Trung bình - Đếm số học sinh thuộc phân loại này
            COUNT(bc.HocSinhID) AS TrungBinh_SoLuong
        FROM dbo.tblBaoCao_Cambridge bc
            INNER JOIN dbo.tblHocSinhLop hsl ON hsl.HocSinhID = bc.HocSinhID AND hsl.Enable = 1
            INNER JOIN dbo.tblLop l ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = @NienKhoa
        AND hsl.NienKhoa = l.NienKhoa
        WHERE l.LopID IN (SELECT value FROM STRING_SPLIT(@List_LopID, ','))
            AND bc.HocKi = @Semester
            AND bc.CapID = @CapID
        GROUP BY l.LopID, bc.DanhGiaChung
    ),
    KetQua AS (
        SELECT 
            lp.TenLop,
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN N'Exceeding Requirements/Vượt yêu cầu'
                WHEN N'Đạt' THEN N'Meeting Requirements/Đạt yêu cầu'
                WHEN N'Chưa đạt' THEN N'Not Meeting Requirements/Chưa đạt'
                ELSE lp.DanhGiaChung
            END AS PhanLoai,
            ISNULL(tl.SiSo, 0) AS SiSo,
            
            -- Nghe - Tỷ lệ % = (Số lượng / Sĩ số lớp) * 100
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN ISNULL(tp.Nghe_VuotYeuCau, 0)
                WHEN N'Đạt' THEN ISNULL(tp.Nghe_Dat, 0)
                WHEN N'Chưa đạt' THEN ISNULL(tp.Nghe_ChuaDat, 0)
            END AS Nghe_SoLuong,
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN CAST(ROUND(ISNULL(tp.Nghe_VuotYeuCau, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Đạt' THEN CAST(ROUND(ISNULL(tp.Nghe_Dat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Chưa đạt' THEN CAST(ROUND(ISNULL(tp.Nghe_ChuaDat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
            END AS Nghe_TyLe,
            
            -- Đọc
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN ISNULL(tp.Doc_VuotYeuCau, 0)
                WHEN N'Đạt' THEN ISNULL(tp.Doc_Dat, 0)
                WHEN N'Chưa đạt' THEN ISNULL(tp.Doc_ChuaDat, 0)
            END AS Doc_SoLuong,
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN CAST(ROUND(ISNULL(tp.Doc_VuotYeuCau, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Đạt' THEN CAST(ROUND(ISNULL(tp.Doc_Dat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Chưa đạt' THEN CAST(ROUND(ISNULL(tp.Doc_ChuaDat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
            END AS Doc_TyLe,
            
            -- Viết
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN ISNULL(tp.Viet_VuotYeuCau, 0)
                WHEN N'Đạt' THEN ISNULL(tp.Viet_Dat, 0)
                WHEN N'Chưa đạt' THEN ISNULL(tp.Viet_ChuaDat, 0)
            END AS Viet_SoLuong,
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN CAST(ROUND(ISNULL(tp.Viet_VuotYeuCau, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Đạt' THEN CAST(ROUND(ISNULL(tp.Viet_Dat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Chưa đạt' THEN CAST(ROUND(ISNULL(tp.Viet_ChuaDat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
            END AS Viet_TyLe,
            
            -- Nói
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN ISNULL(tp.Noi_VuotYeuCau, 0)
                WHEN N'Đạt' THEN ISNULL(tp.Noi_Dat, 0)
                WHEN N'Chưa đạt' THEN ISNULL(tp.Noi_ChuaDat, 0)
            END AS Noi_SoLuong,
            CASE lp.DanhGiaChung
                WHEN N'Vượt yêu cầu' THEN CAST(ROUND(ISNULL(tp.Noi_VuotYeuCau, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Đạt' THEN CAST(ROUND(ISNULL(tp.Noi_Dat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
                WHEN N'Chưa đạt' THEN CAST(ROUND(ISNULL(tp.Noi_ChuaDat, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2))
            END AS Noi_TyLe,
            
            -- Trung bình
            ISNULL(tp.TrungBinh_SoLuong, 0) AS TrungBinh_SoLuong,
            CAST(ROUND(ISNULL(tp.TrungBinh_SoLuong, 0) * 100.0 / NULLIF(ISNULL(tl.SiSo, 0), 0), 2) AS DECIMAL(5,2)) AS TrungBinh_TyLe,
            lp.DanhGiaChung
        FROM LopPhanLoai lp
            LEFT JOIN ThongKePhanLoai tp ON tp.LopID = lp.LopID AND tp.DanhGiaChung = lp.DanhGiaChung
            LEFT JOIN ThongKeLop tl ON tl.LopID = lp.LopID
    )
    SELECT 
        TenLop,
        PhanLoai,
        SiSo,
        Nghe_SoLuong,
        ISNULL(Nghe_TyLe, 0) AS Nghe_TyLe,
        Doc_SoLuong,
        ISNULL(Doc_TyLe, 0) AS Doc_TyLe,
        Viet_SoLuong,
        ISNULL(Viet_TyLe, 0) AS Viet_TyLe,
        Noi_SoLuong,
        ISNULL(Noi_TyLe, 0) AS Noi_TyLe,
        TrungBinh_SoLuong,
        ISNULL(TrungBinh_TyLe, 0) AS TrungBinh_TyLe
    FROM KetQua
    ORDER BY TenLop, 
        CASE DanhGiaChung
            WHEN N'Vượt yêu cầu' THEN 1
            WHEN N'Đạt' THEN 2
            WHEN N'Chưa đạt' THEN 3
        END
END
