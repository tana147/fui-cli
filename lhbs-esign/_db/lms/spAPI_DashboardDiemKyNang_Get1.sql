-- [dbo].[spAPI_DashboardDiemKyNang_Get1] 2024, 3, 76, 'S1_Final,S1_Mid', 0
CREATE PROCEDURE [dbo].[spAPI_DashboardDiemKyNang_Get1]
   @NienKhoa INT,
    @CapID INT,
    @MonHocID INT,
    @MaNhomDiem NVARCHAR(MAX), -- Chuỗi các MaCotDiem, phân tách bằng dấu phẩy
    @Is_KyNang BIT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tách chuỗi MaCotDiem thành bảng tạm
    DECLARE @MaNhomDiemTable TABLE (MaNhomDiem NVARCHAR(50));
    INSERT INTO @MaNhomDiemTable (MaNhomDiem)
    SELECT LTRIM(RTRIM(value)) 
    FROM STRING_SPLIT(@MaNhomDiem, ',');

    DECLARE @ExcludedCotDiem TABLE (MaCotDiem NVARCHAR(50));
    IF @Is_KyNang = 1
    BEGIN
        INSERT INTO @ExcludedCotDiem VALUES
            ('S1_Mid_Total_Point'), 
            ('S1_Final_Total_Point'), 
            ('S2_Mid_Total_Point'), 
            ('S2_Final_Total_Point');
    END
    ELSE
    BEGIN
        INSERT INTO @ExcludedCotDiem VALUES
            ('Theme1_Total'),
            ('Theme2_Total'),
            ('Theme3_Total'),
            ('Theme4_Total'),
            ('Theme5_Total'),
            ('Theme6_Total'),
            ('Theme7_Total'),
            ('Theme8_Total');
    END

    -- Query chính
    SELECT 
        @CapID AS CapID,
        CASE WHEN @CapID = 3 THEN tn.KhoiID ELSE tl.KhoiID END AS KhoiID,
        N'Khối ' + CAST(CASE WHEN @CapID = 3 THEN tn.KhoiID ELSE tl.KhoiID END AS VARCHAR) AS TenKhoi,
        CASE WHEN @CapID = 3 THEN tn.NhomID ELSE tl.LopID END AS LopID,
        CASE WHEN @CapID = 3 THEN tn.TenNhom ELSE tl.TenLop END AS TenLop,
        hs.HocSinhID,
        hs.Ho + N' ' + hs.Ten AS HoTen,
        tbdct.MaNhomCotDiem,
        tbdct.TenNhomCotDiem_VI,
        tbdct.TenNhomCotDiem_EN,
        tbdct.MaCotDiem,
        tbdct.TenCotDiem_VI,
        tbdct.TenCotDiem_EN,
        CASE 
            WHEN ISNUMERIC(tkqht.KetQuaDanhGia_VI) = 1 
                 AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) IS NOT NULL THEN 
                CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
            ELSE NULL
        END AS Diem,
        tbdct.ThuTuCotDiem
    FROM 
        dbo.tblKetQuaHocTap tkqht
    INNER JOIN 
        dbo.tblHocSinh hs ON hs.HocSinhID = tkqht.HocSinhID
    INNER JOIN 
        dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID
    INNER JOIN 
        dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
    INNER JOIN 
        dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
    INNER JOIN 
        @MaNhomDiemTable tnd ON tnd.MaNhomDiem = tbdct.MaNhomCotDiem
    LEFT JOIN 
        @ExcludedCotDiem ex ON tbdct.MaCotDiem = ex.MaCotDiem
    LEFT JOIN 
        dbo.tblLop tl ON (@CapID != 3 AND tl.LopID = tkqht.LopID) AND tl.NienKhoa = @NienKhoa
    LEFT JOIN 
        dbo.tblNhom tn ON (@CapID = 3 AND tn.NhomID = tkqht.LopID and tn.IsNhomLMS_GiaoBai = 0)
    WHERE 
        tkqht.NienKhoa = @NienKhoa
        AND tmh.MonHocID = @MonHocID
        AND TRY_CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10, 2)) > 0
        AND ex.MaCotDiem IS NULL
        AND tkqht.Enable = 1
    ORDER BY 
        TenLop, tbdct.ThuTuNhom, tbdct.ThuTuCotDiem;
END