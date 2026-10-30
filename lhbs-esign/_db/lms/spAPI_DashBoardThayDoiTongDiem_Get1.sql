-- [spAPI_DashBoardThayDoiTongDiem_Get1] 2024, 1, 2362, 5,1
-- [spAPI_DashBoardThayDoiTongDiem_Get1] 2024, 6, 2361, 46,1
--  [spAPI_DashBoardThayDoiTongDiem_Get1] 2024, 10,'N241001', 76,1
CREATE PROCEDURE [dbo].[spAPI_DashBoardThayDoiTongDiem_Get1]
    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(10),
    @MonHocID INT,
    @HocKy INT  -- Thêm tham số học kỳ
AS
BEGIN
    DECLARE @MaCotDiem_GK NVARCHAR(50), @MaCotDiem_CK NVARCHAR(50);

    -- Xác định mã cột điểm theo học kỳ
    IF @HocKy = 1 AND @KhoiID IN (6,7,8,9,10,11,12)
    BEGIN
        SET @MaCotDiem_GK = 'S1_Mid_Total_Point';
        SET @MaCotDiem_CK = 'S1_Final_Total_Point';
    END
    ELSE IF @HocKy = 2 AND @KhoiID IN  (6,7,8,9,10,11,12)
    BEGIN
        SET @MaCotDiem_GK = 'S2_Mid_Total_Point';
        SET @MaCotDiem_CK = 'S2_Final_Total_Point';
    END
	 ELSE IF @HocKy = 3 AND @KhoiID IN  (6,7,8,9,10,11,12)
    BEGIN
        SET @MaCotDiem_GK = 'S1_Mid_Total_Point';
        SET @MaCotDiem_CK = 'S2_Final_Total_Point';
    END
    ELSE 
    BEGIN
        SET @MaCotDiem_GK = 'DiemCK_HK1';
        SET @MaCotDiem_CK = 'DiemCK_HK2';
    END


    IF TRY_CAST(@LopID AS INT) IS NOT NULL
    BEGIN
        SELECT 
            tl.LopID,
            tl.TenLop,
            ths.HocSinhID,
            ths.Ho + ' ' + ths.Ten AS HoTen,
            tmh.MonHocName,
            tmh.MonHocID,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS DiemGK,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS DiemCK,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) - 
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS ChenhLechDiem
        FROM dbo.tblKetQuaHocTap tkqht 
        INNER JOIN dbo.tblHocSinh ths ON ths.HocSinhID = tkqht.HocSinhID
        INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
        INNER JOIN dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.NienKhoa = @NienKhoa
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID 
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        WHERE tkqht.NienKhoa = @NienKhoa
            AND tl.KhoiID = @KhoiID
            AND (@LopID IS NULL OR tl.LopID = @LopID)
            AND (@MonHocID IS NULL OR tmh.MonHocID = @MonHocID)
            AND tbdct.MaCotDiem IN (@MaCotDiem_GK, @MaCotDiem_CK)
            AND tkqht.KetQuaDanhGia_VI IS NOT NULL
            AND tkqht.Enable = 1
        GROUP BY 
            tl.LopID, tl.TenLop, ths.HocSinhID, ths.Ho, ths.Ten, tmh.MonHocName, tmh.MonHocID
        HAVING 
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK THEN 1 ELSE 0 END) > 0
            AND MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK THEN 1 ELSE 0 END) > 0
        ORDER BY tmh.MonHocName, ChenhLechDiem DESC
    END
    ELSE
    BEGIN
        SELECT 
            n.NhomID AS LopID,
            n.TenNhom AS TenLop,
            ths.HocSinhID,
            ths.Ho + ' ' + ths.Ten AS HoTen,
            tmh.MonHocName,
            tmh.MonHocID,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS DiemGK,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS DiemCK,
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) - 
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK 
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) END) AS ChenhLechDiem
        FROM dbo.tblKetQuaHocTap tkqht 
        INNER JOIN dbo.tblHocSinh ths ON ths.HocSinhID = tkqht.HocSinhID
        INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
        INNER JOIN dbo.tblNhom n ON n.NhomID = tkqht.LopID and n.IsNhomLMS_GiaoBai = 0
        INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID 
        INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
        INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        WHERE tkqht.NienKhoa = @NienKhoa
            AND n.KhoiID = @KhoiID
            AND (@LopID IS NULL OR n.NhomID = @LopID)
            AND (@MonHocID IS NULL OR tmh.MonHocID = @MonHocID)
            AND tbdct.MaCotDiem IN (@MaCotDiem_GK, @MaCotDiem_CK)
            AND tkqht.KetQuaDanhGia_VI IS NOT NULL
            AND tkqht.Enable = 1
        GROUP BY 
            n.NhomID, n.TenNhom, ths.HocSinhID, ths.Ho, ths.Ten, tmh.MonHocName, tmh.MonHocID
        HAVING 
            MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_GK THEN 1 ELSE 0 END) > 0
            AND MAX(CASE WHEN tbdct.MaCotDiem = @MaCotDiem_CK THEN 1 ELSE 0 END) > 0
        ORDER BY tmh.MonHocName, ChenhLechDiem DESC
    END
END
