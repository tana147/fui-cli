
CREATE PROCEDURE [dbo].[spAPI_DashBoardThayDoiTongDiem_IELTS_Get]
    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(10),
    @MonHocID INT,
    @HocKy INT  -- Thêm tham số mới
AS
BEGIN
    SET NOCOUNT ON;

    -- Khai báo biến cột điểm theo học kỳ
    DECLARE @MidCotDiem NVARCHAR(50);
    DECLARE @FinalCotDiem NVARCHAR(50);

    -- Xác định cột điểm giữa kỳ và cuối kỳ theo học kỳ
    IF @HocKy = 1
    BEGIN
        SET @MidCotDiem = 'S1_Mid_IELTS_Band_Conv';
        SET @FinalCotDiem = 'S1_Final_IELTS_Band_Conv';
    END
    ELSE
    BEGIN
        SET @MidCotDiem = 'S2_Mid_IELTS_Band_Conv';
        SET @FinalCotDiem = 'S1_Final_IELTS_Band_Conv';
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
            -- Điểm giữa kỳ
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE NULL END) AS DiemGK1,
            -- Điểm cuối kỳ
            MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE NULL END) AS DiemCK1,
            -- Chênh lệch điểm
            MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE 0 END) - 
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE 0 END) AS ChenhLechDiem
        FROM 
            dbo.tblKetQuaHocTap tkqht 
            INNER JOIN dbo.tblHocSinh ths ON ths.HocSinhID = tkqht.HocSinhID
            INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
            INNER JOIN dbo.tblLop tl ON tl.LopID = tkqht.LopID AND tl.NienKhoa = @NienKhoa
            INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID 
            INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
            INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        WHERE 
            tkqht.NienKhoa = @NienKhoa
            AND tl.KhoiID = @KhoiID
            AND (@LopID IS NULL OR tl.LopID = @LopID)
            AND (@MonHocID IS NULL OR tmh.MonHocID = @MonHocID)
            AND tbdct.MaCotDiem IN (@MidCotDiem, @FinalCotDiem)
            AND tkqht.KetQuaDanhGia_VI IS NOT NULL
            AND tkqht.Enable = 1
        GROUP BY 
            tl.LopID, tl.TenLop, ths.HocSinhID, ths.Ho, ths.Ten, tmh.MonHocName, tmh.MonHocID
        HAVING 
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem THEN 1 ELSE 0 END) > 0
            AND MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem THEN 1 ELSE 0 END) > 0
        ORDER BY 
            tmh.MonHocName, ChenhLechDiem DESC;
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
            -- Điểm giữa kỳ
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE NULL END) AS DiemGK1,
            -- Điểm cuối kỳ
            MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE NULL END) AS DiemCK1,
            -- Chênh lệch điểm
            MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE 0 END) - 
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem
                     THEN CAST(tkqht.KetQuaDanhGia_VI AS DECIMAL(10,2)) 
                     ELSE 0 END) AS ChenhLechDiem
        FROM 
            dbo.tblKetQuaHocTap tkqht 
            INNER JOIN dbo.tblHocSinh ths ON ths.HocSinhID = tkqht.HocSinhID
            INNER JOIN dbo.tblHocSinhLop thsl ON ths.HocSinhID = thsl.HocSinhID
            INNER JOIN dbo.tblNhom n ON n.NhomID = tkqht.LopID and n.IsNhomLMS_GiaoBai = 0
            INNER JOIN dbo.TemplateBangDiemChiTiet tbdct ON tbdct.CotDiemID = tkqht.CotDiemID 
            INNER JOIN dbo.tblMonHocLop tmhl ON tmhl.MonHocLopID = tkqht.MonHocLopID
            INNER JOIN dbo.tblMonHoc tmh ON tmh.MonHocID = tmhl.MonHocID
        WHERE 
            tkqht.NienKhoa = @NienKhoa
            AND n.KhoiID = @KhoiID
            AND (@LopID IS NULL OR n.NhomID = @LopID)
            AND (@MonHocID IS NULL OR tmh.MonHocID = @MonHocID)
            AND tbdct.MaCotDiem IN (@MidCotDiem, @FinalCotDiem)
            AND tkqht.KetQuaDanhGia_VI IS NOT NULL
            AND tkqht.Enable = 1
        GROUP BY 
            n.NhomID, n.TenNhom, ths.HocSinhID, ths.Ho, ths.Ten, tmh.MonHocName, tmh.MonHocID
        HAVING 
            MAX(CASE WHEN tbdct.MaCotDiem = @MidCotDiem THEN 1 ELSE 0 END) > 0
            AND MAX(CASE WHEN tbdct.MaCotDiem = @FinalCotDiem THEN 1 ELSE 0 END) > 0
        ORDER BY 
            tmh.MonHocName, ChenhLechDiem DESC;
    END
END
