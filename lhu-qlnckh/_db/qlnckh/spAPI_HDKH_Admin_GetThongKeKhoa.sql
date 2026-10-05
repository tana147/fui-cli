CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetThongKeKhoa]
    @KhoaID VARCHAR(50),
    @NamHoc INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) -- Giữ lại cho đúng chuẩn
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================================
    -- BƯỚC 1: TÍNH TOÁN CHI TIẾT CHO TỪNG GIẢNG VIÊN
    -- ====================================================================================
    CREATE TABLE #GiangVienStats (
        NhanVienID VARCHAR(9), HoTen NVARCHAR(150), KhoaID VARCHAR(50), DinhMucGoc DECIMAL(10,2), 
        TongGioMienGiam DECIMAL(10,2), SoGioBaoLuuNamTruoc DECIMAL(10,2), SoGioThieuNamTruoc DECIMAL(10,2),
        NghiaVuTrongNam DECIMAL(10,2), SoGioPhaiThucHien DECIMAL(10,2), TongGioDaThucHien DECIMAL(10,2),
        KetQua NVARCHAR(50), BaoLuu_Thieu_TrongNam DECIMAL(10,2), SORT INT,
        ChoDuyet INT
    );
    DECLARE @GiangVienKhoa TABLE (NhanVienID VARCHAR(9), HoTen NVARCHAR(150), HocViID INT, SORT INT);
    INSERT INTO @GiangVienKhoa (NhanVienID, HoTen, HocViID, SORT)
    SELECT NV.MaNV, NV.HoTen, NV.HocViID, NV.SORT
    FROM dbo.NhanVien AS NV
    WHERE NV.MaDonVi = @KhoaID AND NV.Is_ThamGiaNCKH = 1 and IsActive = 1

    DECLARE @CurrentNhanVienID VARCHAR(9);
    DECLARE cur CURSOR FOR SELECT NhanVienID FROM @GiangVienKhoa ORDER BY SORT;
    OPEN cur; FETCH NEXT FROM cur INTO @CurrentNhanVienID;
    WHILE @@FETCH_STATUS = 0 BEGIN
        DECLARE @DinhMucGoc DECIMAL(10,2)=0, @TongGioMienGiam DECIMAL(10,2)=0, @SoGioBaoLuuNamTruoc DECIMAL(10,2)=0,
                @SoGioThieuNamTruoc DECIMAL(10,2)=0, @TongGioDaThucHien DECIMAL(10,2)=0, @NghiaVuTrongNam DECIMAL(10,2)=0,
                @PhaiThucHien DECIMAL(10,2)=0, @ChenhLech DECIMAL(10,2)=0, @KetQua NVARCHAR(50)=N'Chưa đạt';
        
        SELECT @DinhMucGoc = ISNULL(CD.DinhMucGioChuan, 0) FROM dbo.NhanVien NV JOIN dbo.tblHDKH_DM_ChucDanhHocVi CD ON NV.HocViID = CD.ID WHERE NV.MaNV = @CurrentNhanVienID;
        SELECT @TongGioMienGiam = ISNULL(SUM(SoGioMienGiam), 0) FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc AND IsDeleted = 0;
        SELECT @SoGioBaoLuuNamTruoc = ISNULL(SoGioBaoLuuNamTiepTheo, 0), @SoGioThieuNamTruoc = ISNULL(SoGioThieuNamTiepTheo, 0) FROM dbo.tblHDKH_TongHop_KetQua_NamHoc WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc - 1 AND IsDeleted = 0;
        
        SELECT @TongGioDaThucHien = ISNULL(SUM(KQC.SoGio_DaDuyet), 0)
        FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
        WHERE KQC.NhanVienID = @CurrentNhanVienID AND KQC.IsDeleted = 0 AND KQC.TrangThaiDuyet LIKE '%DA_DUYET%'
        AND EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S WHERE S.SubmissionID = KQC.SubmissionID AND S.NamHoc = @NamHoc);

        SET @NghiaVuTrongNam = @DinhMucGoc - @TongGioMienGiam -(IIF(@SoGioBaoLuuNamTruoc > @DinhMucGoc/2, @DinhMucGoc/2, @SoGioBaoLuuNamTruoc));
        IF @NghiaVuTrongNam < 0 SET @NghiaVuTrongNam = 0;
        -- SET @PhaiThucHien = @NghiaVuTrongNam + @SoGioThieuNamTruoc;
        SET @PhaiThucHien = @NghiaVuTrongNam ;
        DECLARE @TongGioTichLuy DECIMAL(10,2) = @TongGioDaThucHien;
        SET @ChenhLech = @TongGioTichLuy - @PhaiThucHien;        
        IF @ChenhLech >= 0 SET @KetQua = N'Đạt';
       -- IF @ChenhLech = 0 AND  @TongGioMienGiam > 0 SET @KetQua = N'Đạt';

        -- 12/5/2016 Tân bổ sung số hoạt động chờ duyệt của từng giảng viên
        DECLARE @ChoDuyet INT = 0
        SELECT @ChoDuyet = COUNT(KQC.KetQuaID)
        FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
        WHERE KQC.TrangThaiDuyet = 'CHO_DUYET'
        AND EXISTS (
            SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission sub
            WHERE sub.NamHoc = @NamHoc AND KQC.SubmissionID = sub.SubmissionID
            AND sub.IsDeleted = 0
        )
        AND KQC.NhanVienID = @CurrentNhanVienID
        AND KQC.IsDeleted = 0
        
        INSERT INTO #GiangVienStats (NhanVienID, HoTen, KhoaID, DinhMucGoc, TongGioMienGiam, SoGioBaoLuuNamTruoc, SoGioThieuNamTruoc, NghiaVuTrongNam, SoGioPhaiThucHien, TongGioDaThucHien, KetQua, BaoLuu_Thieu_TrongNam, SORT, ChoDuyet)
        SELECT @CurrentNhanVienID, GV.HoTen, @KhoaID, @DinhMucGoc, @TongGioMienGiam, @SoGioBaoLuuNamTruoc, @SoGioThieuNamTruoc, @NghiaVuTrongNam, @PhaiThucHien, @TongGioDaThucHien, @KetQua, @ChenhLech, GV.SORT, @ChoDuyet
        FROM @GiangVienKhoa AS GV WHERE GV.NhanVienID = @CurrentNhanVienID;

        FETCH NEXT FROM cur INTO @CurrentNhanVienID;
    END
    CLOSE cur; DEALLOCATE cur;

    -- ====================================================================================
    -- BƯỚC 2: TRẢ VỀ CÁC TẬP KẾT QUẢ
    -- ====================================================================================

    -- Result Set 1: Thống kê tổng quan của Khoa
    SELECT
        COUNT(1) AS TongSoGiangVien,
        SUM(CASE WHEN KetQua = N'Đạt' THEN 1 ELSE 0 END) AS SoGiangVienDat,
        SUM(CASE WHEN KetQua = N'Chưa đạt' THEN 1 ELSE 0 END) AS SoGiangVienChuaDat,
        CASE WHEN COUNT(1) > 0 THEN CAST(SUM(CASE WHEN KetQua = N'Đạt' THEN 1 ELSE 0 END) AS DECIMAL(10,2)) * 100 / COUNT(1) ELSE 0 END AS TyLeHoanThanh,
        AVG(TongGioDaThucHien) AS SoGioTB,
        
        -- ======================================================================
        -- SỬA LẠI LOGIC ĐẾM HOẠT ĐỘNG CHỜ DUYỆT
        -- ======================================================================
        (
            SELECT COUNT(1) 
            FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
            JOIN dbo.NhanVien NV ON KQC.NhanVienID = NV.MaNV
            WHERE 
                KQC.TrangThaiDuyet = 'CHO_DUYET' 
                AND KQC.IsDeleted = 0
                AND NV.MaDonVi = @KhoaID
                    and nv.IsActive = 1
                    and nv.Is_ThamGiaNCKH = 1
                AND EXISTS (
                    SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S 
                    WHERE S.SubmissionID = KQC.SubmissionID AND S.NamHoc = @NamHoc
                    AND s.IsDeleted = 0
                )
        ) AS HoatDongChoDuyet

    FROM #GiangVienStats;

    -- Result Set 2: Danh sách chi tiết giảng viên của Khoa
    SELECT 
        NhanVienID, HoTen, DinhMucGoc, TongGioMienGiam, SoGioBaoLuuNamTruoc, SoGioThieuNamTruoc,
        NghiaVuTrongNam, SoGioPhaiThucHien, TongGioDaThucHien, KetQua, BaoLuu_Thieu_TrongNam, ChoDuyet
    FROM #GiangVienStats
    ORDER BY SORT, HoTen;

    DROP TABLE #GiangVienStats;
END;
