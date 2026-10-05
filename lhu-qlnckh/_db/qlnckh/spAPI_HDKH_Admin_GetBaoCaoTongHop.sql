CREATE  PROCEDURE [dbo].[spAPI_HDKH_Admin_GetBaoCaoTongHop] -- 2025,'',''
    @NamHoc INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================================
    -- BƯỚC 1: TÍNH TOÁN VÀ LƯU KẾT QUẢ CỦA TẤT CẢ GIẢNG VIÊN VÀO BẢNG TẠM
    -- ====================================================================================
    CREATE TABLE #FullReportData (
        MaNV VARCHAR(9), HoTen NVARCHAR(150), MaDonVi VARCHAR(50), TenDonVi NVARCHAR(255),
        NhiemVuTrongDonVi NVARCHAR(255), MienGiamDinhMuc DECIMAL(10,2), SoGioQuyDoiTrongNam DECIMAL(10,2),
        SoGioThieuNamTruoc DECIMAL(10,2), SoGioBaoLuuNamTruoc DECIMAL(10,2),
        SoGioChuanDuocChuyen DECIMAL(10,2), NghiaVuTrongNam DECIMAL(10,2), SoGioPhaiThucHien DECIMAL(10,2),
        DanhGiaKetQua NVARCHAR(50), SoGioBaoLuu_Thieu DECIMAL(10,2), SoGioBaoLuuNamTiepTheo DECIMAL(10,2),
        LyDoMienGiam NVARCHAR(500), SORT INT
    );
    
    DECLARE @AllGiangVien TABLE (NhanVienID VARCHAR(9), HoTen NVARCHAR(150), HocViID INT, KhoaID VARCHAR(50), TenDonVi NVARCHAR(255), NhiemVu NVARCHAR(255), SORT INT);
    INSERT INTO @AllGiangVien (NhanVienID, HoTen, HocViID, KhoaID, TenDonVi, NhiemVu, SORT)
    SELECT NV.MaNV, NV.HoTen, NV.HocViID, NV.MaDonVi, DV.TenDonVi, NV.ChucVu, NV.SORT
    FROM dbo.NhanVien AS NV JOIN dbo.DonVi DV ON NV.MaDonVi = DV.MaDonVi WHERE NV.Is_ThamGiaNCKH = 1 and IsActive = 1 and dv.CoThamGiaNCKH = 1 and dv.Is_Xoa = 0

    DECLARE @CurrentNhanVienID VARCHAR(9);
    DECLARE cur CURSOR FOR SELECT NhanVienID FROM @AllGiangVien;
    OPEN cur;
    FETCH NEXT FROM cur INTO @CurrentNhanVienID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @DinhMucGoc DECIMAL(10,2)=0, @TongGioMienGiam DECIMAL(10,2)=0, @LyDoMienGiam NVARCHAR(500),
                @SoGioBaoLuuNamTruoc DECIMAL(10,2)=0, @SoGioThieuNamTruoc DECIMAL(10,2)=0, 
                @TongGioDaThucHien DECIMAL(10,2)=0, @NghiaVuTrongNam DECIMAL(10,2)=0, 
                @PhaiThucHien DECIMAL(10,2)=0, @ChenhLech DECIMAL(10,2)=0, @KetQua NVARCHAR(50)=N'Chưa đạt',
                @SoGioBaoLuuNamTiepTheo DECIMAL(10,2)=0, @SoGioThieuNamTiepTheo DECIMAL(10,2)=0,
                @NghiaVuToiThieu DECIMAL(10,2)=0;

        SELECT @DinhMucGoc = ISNULL(CD.DinhMucGioChuan, 0) FROM @AllGiangVien GV JOIN dbo.tblHDKH_DM_ChucDanhHocVi CD ON GV.HocViID = CD.ID WHERE GV.NhanVienID = @CurrentNhanVienID;
        SELECT @TongGioMienGiam = ISNULL(SUM(SoGioMienGiam), 0), @LyDoMienGiam = STUFF((SELECT '; ' + LyDo FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc AND IsDeleted = 0 FOR XML PATH('')), 1, 2, '')
        FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc AND IsDeleted = 0;
        SELECT @SoGioBaoLuuNamTruoc = ISNULL(SoGioBaoLuuNamTiepTheo, 0), @SoGioThieuNamTruoc = ISNULL(SoGioThieuNamTiepTheo, 0) FROM dbo.tblHDKH_TongHop_KetQua_NamHoc WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc - 1 AND IsDeleted = 0;
        SELECT @TongGioDaThucHien = ISNULL(SUM(KQC.SoGio_DaDuyet), 0) FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
        WHERE KQC.NhanVienID = @CurrentNhanVienID AND KQC.IsDeleted = 0 AND KQC.TrangThaiDuyet LIKE '%DA_DUYET%'
          AND EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S WHERE S.SubmissionID = KQC.SubmissionID AND S.NamHoc = @NamHoc);

       SET @NghiaVuTrongNam = @DinhMucGoc - @TongGioMienGiam -(IIF(@SoGioBaoLuuNamTruoc > @DinhMucGoc/2, @DinhMucGoc/2, @SoGioBaoLuuNamTruoc));
        IF @NghiaVuTrongNam < 0 SET @NghiaVuTrongNam = 0;
        -- SET @PhaiThucHien = @NghiaVuTrongNam + @SoGioThieuNamTruoc;
        SET @PhaiThucHien = @NghiaVuTrongNam ;
        DECLARE @TongGioTichLuy DECIMAL(10,2) = @TongGioDaThucHien;
        SET @ChenhLech = @TongGioTichLuy - @PhaiThucHien;        
        IF @ChenhLech >= 0 SET @KetQua = N'Đạt';
        
        SET @NghiaVuToiThieu = @NghiaVuTrongNam * 0.5;
        IF @ChenhLech >= 0 BEGIN
            SET @SoGioThieuNamTiepTheo = 0;
            IF @TongGioDaThucHien >= @NghiaVuToiThieu
                SET @SoGioBaoLuuNamTiepTheo = CASE WHEN @ChenhLech < @NghiaVuToiThieu THEN @ChenhLech ELSE @NghiaVuToiThieu END;
            ELSE SET @SoGioBaoLuuNamTiepTheo = 0;
        END ELSE BEGIN
            SET @SoGioBaoLuuNamTiepTheo = 0;
            SET @SoGioThieuNamTiepTheo = -@ChenhLech;
        END

        INSERT INTO #FullReportData (MaNV, HoTen, TenDonVi, NhiemVuTrongDonVi, MienGiamDinhMuc, SoGioQuyDoiTrongNam, SoGioThieuNamTruoc, SoGioBaoLuuNamTruoc,
            SoGioChuanDuocChuyen, NghiaVuTrongNam, SoGioPhaiThucHien, DanhGiaKetQua, SoGioBaoLuu_Thieu, SoGioBaoLuuNamTiepTheo, LyDoMienGiam, SORT)
        SELECT @CurrentNhanVienID, GV.HoTen, GV.TenDonVi, GV.NhiemVu, @TongGioMienGiam, @TongGioDaThucHien, @SoGioThieuNamTruoc, @SoGioBaoLuuNamTruoc,
               @SoGioBaoLuuNamTruoc, @NghiaVuTrongNam, @PhaiThucHien, @KetQua, @ChenhLech, @SoGioBaoLuuNamTiepTheo, @LyDoMienGiam, GV.SORT
        FROM @AllGiangVien AS GV WHERE GV.NhanVienID = @CurrentNhanVienID;

        FETCH NEXT FROM cur INTO @CurrentNhanVienID;
    END
    CLOSE cur; DEALLOCATE cur;

    -- ====================================================================================
    -- BƯỚC 2: TRẢ VỀ CÁC TẬP KẾT QUẢ
    -- ====================================================================================

    -- Result Set 1: Thống kê theo Khoa (cho trang 2 của file báo cáo)
    SELECT
        DV.TenDonVi AS DonVi,
        COUNT(NV.MaNV) AS TongSoGiangVien,
        SUM(CASE WHEN FR.DanhGiaKetQua = N'Đạt' THEN 1 ELSE 0 END) AS Dat,
        SUM(CASE WHEN FR.DanhGiaKetQua = N'Chưa đạt' THEN 1 ELSE 0 END) AS KhongDat,
        ROUND(CASE WHEN COUNT(NV.MaNV) > 0 THEN CAST(SUM(CASE WHEN FR.DanhGiaKetQua = N'Đạt' THEN 1 ELSE 0 END) AS DECIMAL(10, 2)) * 100 / COUNT(NV.MaNV) ELSE 0 END, 2) AS TyLeDat,
        ROUND(CASE WHEN COUNT(NV.MaNV) > 0 THEN CAST(SUM(CASE WHEN FR.DanhGiaKetQua = N'Chưa đạt' THEN 1 ELSE 0 END) AS DECIMAL(10, 2)) * 100 / COUNT(NV.MaNV) ELSE 0 END, 2) AS TyLeKhongDat
FROM
    #FullReportData FR
JOIN dbo.NhanVien NV ON
    FR.MaNV = NV.MaNV
JOIN dbo.DonVi DV ON
    NV.MaDonVi = DV.MaDonVi
where DV.CoThamGiaNCKH = 1
    and DV.Is_Xoa = 0
GROUP BY
    DV.TenDonVi
ORDER BY
    DV.TenDonVi;

    -- Result Set 2: Danh sách Giảng viên ĐẠT (cho trang 3-17)
    SELECT 
        MaNV, HoTen, TenDonVi, NhiemVuTrongDonVi, MienGiamDinhMuc, SoGioQuyDoiTrongNam, SoGioThieuNamTruoc, SoGioBaoLuuNamTruoc,
        SoGioChuanDuocChuyen, NghiaVuTrongNam, SoGioPhaiThucHien, DanhGiaKetQua, SoGioBaoLuu_Thieu, SoGioBaoLuuNamTiepTheo, LyDoMienGiam
    FROM #FullReportData
    WHERE DanhGiaKetQua = N'Đạt'
    ORDER BY TenDonVi, SORT, HoTen
    
    -- Result Set 3: Danh sách Giảng viên KHÔNG ĐẠT (cho trang 18)
    SELECT
         MaNV, HoTen, TenDonVi, NhiemVuTrongDonVi, MienGiamDinhMuc, SoGioQuyDoiTrongNam, SoGioThieuNamTruoc, SoGioBaoLuuNamTruoc,
        SoGioChuanDuocChuyen, NghiaVuTrongNam, SoGioPhaiThucHien, DanhGiaKetQua, SoGioBaoLuu_Thieu, SoGioBaoLuuNamTiepTheo, LyDoMienGiam
    FROM #FullReportData
    WHERE DanhGiaKetQua = N'Chưa đạt'
    ORDER BY TenDonVi, SORT, HoTen

    -- Dọn dẹp
    DROP TABLE #FullReportData;
END;
