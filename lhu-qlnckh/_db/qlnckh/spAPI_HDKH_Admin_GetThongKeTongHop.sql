CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetThongKeTongHop]
    @NamHoc INT,
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX) -- Giữ lại cho đúng chuẩn
AS
BEGIN
    SET NOCOUNT ON;

    -- ====================================================================================
    -- BƯỚC 1: TÍNH TOÁN VÀ LƯU KẾT QUẢ CHI TIẾT CỦA TẤT CẢ GIẢNG VIÊN VÀO BẢNG TẠM
    -- ====================================================================================
    CREATE TABLE #GiangVienStats (
        NhanVienID VARCHAR(9), KhoaID VARCHAR(50), DaThucHien DECIMAL(10,2), KetQua NVARCHAR(50)
    );

    -- Lấy danh sách tất cả giảng viên đang hoạt động
    DECLARE @AllGiangVien TABLE (NhanVienID VARCHAR(9), HocViID INT, KhoaID VARCHAR(50));
    INSERT INTO @AllGiangVien (NhanVienID, HocViID, KhoaID)
    SELECT MaNV, HocViID, MaDonVi FROM dbo.NhanVien WHERE Is_ThamGiaNCKH = 1 and IsActive = 1

    -- Lặp qua từng giảng viên để tính toán
    DECLARE @CurrentNhanVienID VARCHAR(9);
    DECLARE cur CURSOR FOR SELECT NhanVienID FROM @AllGiangVien;
    OPEN cur;
    FETCH NEXT FROM cur INTO @CurrentNhanVienID;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Khai báo các biến tính toán
        DECLARE @DinhMucGoc DECIMAL(10,2)=0, @TongGioMienGiam DECIMAL(10,2)=0, @SoGioBaoLuuNamTruoc DECIMAL(10,2)=0,
                @SoGioThieuNamTruoc DECIMAL(10,2)=0, @TongGioDaThucHien DECIMAL(10,2)=0, @NghiaVuTrongNam DECIMAL(10,2)=0,
                @PhaiThucHien DECIMAL(10,2)=0, @ChenhLech DECIMAL(10,2)=0, @KetQua NVARCHAR(50)=N'Chưa đạt',
                @KhoaID_GV VARCHAR(50);

        -- Lấy KhoaID và HocViID
        SELECT @KhoaID_GV = KhoaID FROM @AllGiangVien WHERE NhanVienID = @CurrentNhanVienID;

        -- 1. Lấy Định mức gốc
        SELECT @DinhMucGoc = ISNULL(CD.DinhMucGioChuan, 0)
        FROM @AllGiangVien GV JOIN dbo.tblHDKH_DM_ChucDanhHocVi CD ON GV.HocViID = CD.ID
        WHERE GV.NhanVienID = @CurrentNhanVienID;

        -- 2. Lấy Tổng giờ miễn giảm
        SELECT @TongGioMienGiam = ISNULL(SUM(SoGioMienGiam), 0)
        FROM dbo.tblHDKH_MienGiam WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc AND IsDeleted = 0;

        -- 3. Lấy Bảo lưu/Thiếu từ năm trước
        SELECT @SoGioBaoLuuNamTruoc = ISNULL(SoGioBaoLuuNamTiepTheo, 0), @SoGioThieuNamTruoc = ISNULL(SoGioThieuNamTiepTheo, 0)
        FROM dbo.tblHDKH_TongHop_KetQua_NamHoc WHERE NhanVienID = @CurrentNhanVienID AND NamHoc = @NamHoc - 1 AND IsDeleted = 0;

        -- 4. Lấy Tổng giờ đã được duyệt
        SELECT @TongGioDaThucHien = ISNULL(SUM(KQC.SoGio_DaDuyet), 0)
        FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan KQC
        WHERE KQC.NhanVienID = @CurrentNhanVienID AND KQC.IsDeleted = 0 AND KQC.TrangThaiDuyet LIKE '%DA_DUYET%'
          AND EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S WHERE S.SubmissionID = KQC.SubmissionID AND S.NamHoc = @NamHoc);

        -- 5. Thực hiện tính toán
        SET @NghiaVuTrongNam = @DinhMucGoc - @TongGioMienGiam;
        IF @NghiaVuTrongNam < 0 SET @NghiaVuTrongNam = 0;
        SET @PhaiThucHien = @NghiaVuTrongNam + @SoGioThieuNamTruoc;
        DECLARE @TongGioTichLuy DECIMAL(10,2) = @TongGioDaThucHien + @SoGioBaoLuuNamTruoc;
        SET @ChenhLech = @TongGioTichLuy - @PhaiThucHien;
        IF @ChenhLech >= 0 SET @KetQua = N'Đạt';

        -- 6. Insert kết quả vào bảng tạm
        INSERT INTO #GiangVienStats (NhanVienID, KhoaID, DaThucHien, KetQua)
        VALUES (@CurrentNhanVienID, @KhoaID_GV, @TongGioDaThucHien, @KetQua);

        FETCH NEXT FROM cur INTO @CurrentNhanVienID;
    END
    CLOSE cur;
    DEALLOCATE cur;

    -- ====================================================================================
    -- BƯỚC 2: TRẢ VỀ CÁC TẬP KẾT QUẢ TỔNG HỢP
    -- ====================================================================================

    -- Result Set 1: Thống kê Toàn trường
    SELECT
        COUNT(1) AS TongSoGiangVien,
        CASE WHEN COUNT(1) > 0 THEN CAST(SUM(CASE WHEN KetQua = N'Đạt' THEN 1 ELSE 0 END) AS DECIMAL(10,2)) * 100 / COUNT(1) ELSE 0 END AS TyLeHoanThanh,
        AVG(DaThucHien) AS SoGioTB,
        (SELECT COUNT(1) FROM dbo.tblHDKH_KeKhai_KetQua_CaNhan WHERE TrangThaiDuyet = 'CHO_DUYET' AND IsDeleted = 0 AND EXISTS (SELECT 1 FROM dbo.tblHDKH_KeKhai_Submission S WHERE S.SubmissionID = tblHDKH_KeKhai_KetQua_CaNhan.SubmissionID AND S.NamHoc = @NamHoc)) AS HoatDongChoDuyet
    FROM #GiangVienStats;

    -- Result Set 2: Thống kê theo từng Khoa
    SELECT
        GVS.KhoaID,
        DV.TenDonVi AS TenKhoa,
        COUNT(1) AS TongSoGiangVien,
        CASE WHEN COUNT(1) > 0 THEN CAST(SUM(CASE WHEN GVS.KetQua = N'Đạt' THEN 1 ELSE 0 END) AS DECIMAL(10,2)) * 100 / COUNT(1) ELSE 0 END AS TyLeHoanThanh,
        AVG(GVS.DaThucHien) AS SoGioTB
    FROM #GiangVienStats AS GVS
    JOIN dbo.DonVi AS DV ON GVS.KhoaID = DV.MaDonVi
    GROUP BY GVS.KhoaID, DV.TenDonVi
    ORDER BY DV.TenDonVi;
    
    DROP TABLE #GiangVienStats;
END
