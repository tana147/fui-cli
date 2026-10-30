CREATE   PROCEDURE dbo.spAPI_SoGVCN_LichSuChinhSua_Get_ChiTiet

    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(20),
    @MaTab VARCHAR(100),
    @MaMuc VARCHAR(100),
    @Ngay VARCHAR(10),
    @Gio VARCHAR(5),
    @NgayTu VARCHAR(10),
    @NgayDen VARCHAR(10)

AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DateFrom DATE = COALESCE(
        TRY_CONVERT(DATE, NULLIF(@NgayTu, ''), 23),
        TRY_CONVERT(DATE, NULLIF(@NgayTu, ''), 103)
    );
    DECLARE @DateTo DATE = COALESCE(
        TRY_CONVERT(DATE, NULLIF(@NgayDen, ''), 23),
        TRY_CONVERT(DATE, NULLIF(@NgayDen, ''), 103)
    );
    DECLARE @SingleDate DATE = COALESCE(
        TRY_CONVERT(DATE, NULLIF(@Ngay, ''), 23),
        TRY_CONVERT(DATE, NULLIF(@Ngay, ''), 103)
    );
    IF @DateFrom IS NULL AND @DateTo IS NULL AND @SingleDate IS NOT NULL
    BEGIN
        SET @DateFrom = @SingleDate;
        SET @DateTo = @SingleDate;
    END;
    DECLARE @FilterHour INT = TRY_CONVERT(INT, LEFT(NULLIF(@Gio, ''), 2));

    -- Dùng table variable để tAPI/SQL Server suy ra được metadata result set;
    -- #temp table làm FUI không mô tả được schema và trả lỗi tải dữ liệu.
    DECLARE @RawLog TABLE
    (
        SourceTable varchar(128) NOT NULL,
        SourceLabel nvarchar(200) NOT NULL,
        AuditID bigint NOT NULL,
        SoGVCNID int NULL,
        NienKhoa int NULL,
        KhoiID int NULL,
        LopID varchar(20) NULL,
        MaTab varchar(100) NOT NULL,
        TenTab nvarchar(200) NOT NULL,
        MaMuc varchar(100) NOT NULL,
        TenMuc nvarchar(255) NOT NULL,
        NhomMuc nvarchar(150) NOT NULL,
        TenDong nvarchar(200) NULL,
        NoiDungChinhSua nvarchar(max) NOT NULL,
        GiaTriCu nvarchar(max) NULL,
        GiaTriMoi nvarchar(max) NULL,
        CreateUser varchar(50) NULL,
        HoTenUser nvarchar(200) NULL,
        CreateTime datetime NULL,
        AuditAction char(1) NULL,
        AuditTabGoc varchar(100) NULL,
        AuditEvent varchar(50) NULL
    );


    -- Lọc tab/mục ngay tại từng bảng nguồn để không gom toàn bộ 24 bảng
    -- khi người dùng chỉ mở một mục lịch sử cụ thể.
    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCN_Log' AS SourceTable,
        N'Tổng quan Sổ GVCN' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCN_Log',
        N'Tổng quan Sổ GVCN',
        'records',
        N'Tổng quan Sổ GVCN',
        N'tblSoGVCN_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCN_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCN_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCN_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'tong-quan-so-gvcn')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'tong-quan-so-gvcn')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNBanDaiDienCMHS_Log' AS SourceTable,
        N'Ban đại diện CMHS' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNBanDaiDienCMHS_Log',
        N'Ban đại diện CMHS',
        'records',
        N'Ban đại diện CMHS',
        N'tblSoGVCNBanDaiDienCMHS_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNBanDaiDienCMHS_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNBanDaiDienCMHS_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNBanDaiDienCMHS_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN src.AuditKhoiID BETWEEN 1 AND 5 THEN 'to-chuc-lop' ELSE 'chi-tieu' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'ban-dai-dien-cmhs')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNCanBoLop_Log' AS SourceTable,
        N'Cán bộ lớp' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNCanBoLop_Log',
        N'Cán bộ lớp',
        'records',
        N'Cán bộ lớp',
        N'tblSoGVCNCanBoLop_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNCanBoLop_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNCanBoLop_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNCanBoLop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN src.AuditKhoiID BETWEEN 1 AND 5 THEN 'to-chuc-lop' ELSE 'chi-tieu' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'can-bo-lop')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNChiTieu_Log' AS SourceTable,
        N'Chỉ tiêu' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNChiTieu_Log',
        N'Chỉ tiêu',
        'records',
        N'Chỉ tiêu',
        N'tblSoGVCNChiTieu_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNChiTieu_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNChiTieu_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNChiTieu_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'chi-tieu')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = CASE src.LoaiChiTieu
            WHEN 'DANH_HIEU' THEN 'danh-hieu'
            WHEN 'PHONG_TRAO' THEN 'hoat-dong-phong-trao'
            ELSE 'chi-tieu-giao-duc'
          END)
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNGiaoVienBoMon_Log' AS SourceTable,
        N'Giáo viên bộ môn' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNGiaoVienBoMon_Log',
        N'Giáo viên bộ môn',
        'records',
        N'Giáo viên bộ môn',
        N'tblSoGVCNGiaoVienBoMon_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNGiaoVienBoMon_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNGiaoVienBoMon_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNGiaoVienBoMon_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN src.AuditKhoiID BETWEEN 1 AND 5 THEN 'to-chuc-lop' ELSE 'chi-tieu' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'giao-vien-bo-mon')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNHocSinhCanQuanTam_Log' AS SourceTable,
        N'Học sinh cần quan tâm' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNHocSinhCanQuanTam_Log',
        N'Học sinh cần quan tâm',
        'records',
        N'Học sinh cần quan tâm',
        N'tblSoGVCNHocSinhCanQuanTam_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNHocSinhCanQuanTam_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNHocSinhCanQuanTam_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNHocSinhCanQuanTam_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'hs-can-quan-tam')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'hs-can-quan-tam')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNHuongNghiep_Log' AS SourceTable,
        N'Hướng nghiệp' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNHuongNghiep_Log',
        N'Hướng nghiệp',
        'records',
        N'Hướng nghiệp',
        N'tblSoGVCNHuongNghiep_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNHuongNghiep_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNHuongNghiep_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNHuongNghiep_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'huong-nghiep')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'huong-nghiep')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNKeHoachNamHoc_Log' AS SourceTable,
        N'Kế hoạch năm học' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHoc_Log',
        N'Kế hoạch năm học',
        'records',
        N'Kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHoc_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNKeHoachNamHoc_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNKeHoachNamHoc_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHoc_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'ke-hoach-nam-hoc')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'thuan-loi-kho-khan')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNKeHoachNamHocChiTieu_Log' AS SourceTable,
        N'Chỉ tiêu kế hoạch năm học' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHocChiTieu_Log',
        N'Chỉ tiêu kế hoạch năm học',
        'records',
        N'Chỉ tiêu kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHocChiTieu_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNKeHoachNamHocChiTieu_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNKeHoachNamHocChiTieu_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHocChiTieu_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'ke-hoach-nam-hoc')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'duy-tri-so-luong')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNKeHoachNamHocThongKeLop_Log' AS SourceTable,
        N'Thống kê lớp kế hoạch năm học' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHocThongKeLop_Log',
        N'Thống kê lớp kế hoạch năm học',
        'records',
        N'Thống kê lớp kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHocThongKeLop_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNKeHoachNamHocThongKeLop_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNKeHoachNamHocThongKeLop_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHocThongKeLop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'ke-hoach-nam-hoc')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'thong-ke-tinh-hinh')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNKeHoachThang_Log' AS SourceTable,
        N'Kế hoạch tháng' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachThang_Log',
        N'Kế hoạch tháng',
        'records',
        N'Kế hoạch tháng',
        N'tblSoGVCNKeHoachThang_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNKeHoachThang_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNKeHoachThang_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNKeHoachThang_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (
          NULLIF(@MaTab, '') IS NULL
          OR (@MaTab = 'cong-tac-cn' AND src.AuditKhoiID BETWEEN 1 AND 5)
          OR (@MaTab = 'ke-hoach' AND (src.AuditKhoiID IS NULL OR src.AuditKhoiID NOT BETWEEN 1 AND 5))
      )
      AND (
          NULLIF(@MaMuc, '') IS NULL
          OR (@MaMuc = 'ke-hoach-thang' AND src.AuditKhoiID BETWEEN 1 AND 5)
          OR (@MaMuc = 'ke-hoach' AND (src.AuditKhoiID IS NULL OR src.AuditKhoiID NOT BETWEEN 1 AND 5))
      )
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNKeHoachTuan_Log' AS SourceTable,
        N'Kế hoạch tuần' AS SourceLabel,
        src.AuditID,
        NULL AS SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachTuan_Log',
        N'Kế hoạch tuần',
        'records',
        N'Kế hoạch tuần',
        N'tblSoGVCNKeHoachTuan_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNKeHoachTuan_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNKeHoachTuan_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNKeHoachTuan_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (
          NULLIF(@MaTab, '') IS NULL
          OR (@MaTab = 'cong-tac-cn' AND src.AuditKhoiID BETWEEN 1 AND 5)
          OR (@MaTab = 'ke-hoach' AND (src.AuditKhoiID IS NULL OR src.AuditKhoiID NOT BETWEEN 1 AND 5))
      )
      AND (
          NULLIF(@MaMuc, '') IS NULL
          OR (@MaMuc = 'ke-hoach-tuan' AND src.AuditKhoiID BETWEEN 1 AND 5)
          OR (@MaMuc = 'ke-hoach' AND (src.AuditKhoiID IS NULL OR src.AuditKhoiID NOT BETWEEN 1 AND 5))
      )
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNNoiDungHopPHHS_Log' AS SourceTable,
        N'Nội dung họp PHHS' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNNoiDungHopPHHS_Log',
        N'Nội dung họp PHHS',
        'records',
        N'Nội dung họp PHHS',
        N'tblSoGVCNNoiDungHopPHHS_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNNoiDungHopPHHS_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNNoiDungHopPHHS_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNNoiDungHopPHHS_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'noi-dung-hop-ph')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'noi-dung-hop-ph')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNSiSo_Log' AS SourceTable,
        N'Sĩ số' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSiSo_Log',
        N'Sĩ số',
        'records',
        N'Sĩ số',
        N'tblSoGVCNSiSo_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNSiSo_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNSiSo_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNSiSo_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN src.AuditKhoiID BETWEEN 1 AND 5 THEN 'theo-doi-si-so' ELSE 'chi-tieu' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'theo-doi-si-so')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNSoKetHKI_Log' AS SourceTable,
        N'Sơ kết HKI' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSoKetHKI_Log',
        N'Sơ kết HKI',
        'records',
        N'Sơ kết HKI',
        N'tblSoGVCNSoKetHKI_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNSoKetHKI_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNSoKetHKI_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNSoKetHKI_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'so-ket-hk1')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'ket-qua-hk1')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNSoKetHKIDanhGia_Log' AS SourceTable,
        N'Đánh giá sơ kết HKI' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSoKetHKIDanhGia_Log',
        N'Đánh giá sơ kết HKI',
        'records',
        N'Đánh giá sơ kết HKI',
        N'tblSoGVCNSoKetHKIDanhGia_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNSoKetHKIDanhGia_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNSoKetHKIDanhGia_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNSoKetHKIDanhGia_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'so-ket-hk1')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'nang-luc-pham-chat')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTheoDoiPhuHuynhHop_Log' AS SourceTable,
        N'Theo dõi phụ huynh đi họp' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiPhuHuynhHop_Log',
        N'Theo dõi phụ huynh đi họp',
        'records',
        N'Theo dõi phụ huynh đi họp',
        N'tblSoGVCNTheoDoiPhuHuynhHop_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTheoDoiPhuHuynhHop_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTheoDoiPhuHuynhHop_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiPhuHuynhHop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'so-lien-lac')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'so-lien-lac')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTheoDoiRenLuyen_Log' AS SourceTable,
        N'Theo dõi rèn luyện' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiRenLuyen_Log',
        N'Theo dõi rèn luyện',
        'records',
        N'Theo dõi rèn luyện',
        N'tblSoGVCNTheoDoiRenLuyen_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTheoDoiRenLuyen_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTheoDoiRenLuyen_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiRenLuyen_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'ren-luyen')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'ren-luyen')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTheoDoiSiSoThang_Log' AS SourceTable,
        N'Theo dõi sĩ số tháng' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiSiSoThang_Log',
        N'Theo dõi sĩ số tháng',
        'records',
        N'Theo dõi sĩ số tháng',
        N'tblSoGVCNTheoDoiSiSoThang_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTheoDoiSiSoThang_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTheoDoiSiSoThang_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiSiSoThang_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'theo-doi-si-so')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'theo-doi-si-so')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTheoDoiThanhTichHocSinh_Log' AS SourceTable,
        N'Theo dõi thành tích học sinh' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiThanhTichHocSinh_Log',
        N'Theo dõi thành tích học sinh',
        'records',
        N'Theo dõi thành tích học sinh',
        N'tblSoGVCNTheoDoiThanhTichHocSinh_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTheoDoiThanhTichHocSinh_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTheoDoiThanhTichHocSinh_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiThanhTichHocSinh_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'theo-doi-thanh-tich')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'theo-doi-thanh-tich')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNThongKeDoTuoi_Log' AS SourceTable,
        N'Thống kê độ tuổi' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNThongKeDoTuoi_Log',
        N'Thống kê độ tuổi',
        'records',
        N'Thống kê độ tuổi',
        N'tblSoGVCNThongKeDoTuoi_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNThongKeDoTuoi_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNThongKeDoTuoi_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNThongKeDoTuoi_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'thong-ke-do-tuoi')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'thong-ke-do-tuoi')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTongKetNamDanhGia_Log' AS SourceTable,
        N'Đánh giá tổng kết năm' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTongKetNamDanhGia_Log',
        N'Đánh giá tổng kết năm',
        'records',
        N'Đánh giá tổng kết năm',
        N'tblSoGVCNTongKetNamDanhGia_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTongKetNamDanhGia_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTongKetNamDanhGia_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTongKetNamDanhGia_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'tong-ket-nam')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'danh-gia-tong-quan')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNTongKetNamHocC1_Log' AS SourceTable,
        N'Tổng kết năm học C1' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTongKetNamHocC1_Log',
        N'Tổng kết năm học C1',
        'records',
        N'Tổng kết năm học C1',
        N'tblSoGVCNTongKetNamHocC1_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNTongKetNamHocC1_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNTongKetNamHocC1_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNTongKetNamHocC1_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'tong-ket-nam')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'khen-thuong-hoan-thanh')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tblSoGVCNToNhomHocSinh_Log' AS SourceTable,
        N'Tổ/nhóm học sinh' AS SourceLabel,
        src.AuditID,
        src.SoGVCNID,
        src.AuditNienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNToNhomHocSinh_Log',
        N'Tổ/nhóm học sinh',
        'records',
        N'Tổ/nhóm học sinh',
        N'tblSoGVCNToNhomHocSinh_Log',
        LEFT(N'AuditID: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—')
            + CASE WHEN NULLIF(src.AuditEvent, 'unknown/unavailable') IS NOT NULL
                THEN N' | Sự kiện: ' + src.AuditEvent ELSE N'' END, 200),
        CAST(N'Bảng nguồn: ' + N'tblSoGVCNToNhomHocSinh_Log'
            + N' | Bản ghi audit: ' + CONVERT(nvarchar(30), src.AuditID)
            + N' | Hành động: ' + ISNULL(NULLIF(src.AuditAction, ''), N'—') AS nvarchar(max)),
        NULL,
        CAST(N'Chi tiết được truy xuất trực tiếp từ ' + N'tblSoGVCNToNhomHocSinh_Log'
            + N' (AuditID ' + CONVERT(nvarchar(30), src.AuditID) + N').' AS nvarchar(max)),
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), '0'), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        src.AuditAction,
        src.AuditTab,
        src.AuditEvent
    FROM dbo.[tblSoGVCNToNhomHocSinh_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = 'to-chuc-lop')
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = 'to-nhom-hoc-sinh')
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    -- Hai cấp học dùng chung log LMS: snapshot nội dung giữ bản dữ liệu trước cập nhật,
    -- còn bảng *_Lop ghi chính xác các lần đổi trạng thái của kỳ nhận xét.
    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tbl_LOG_NhanXetThang',
        N'Snapshot nội dung nhận xét',
        src.BackupID,
        NULL,
        p.NienKhoa,
        lop.KhoiID,
        CONVERT(varchar(20), p.LopID),
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT THÁNG (LMS)' ELSE N'SỔ LIÊN LẠC ĐIỆN TỬ' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'Đánh giá nhận xét tháng LMS' ELSE N'Thông tin sổ liên lạc điện tử' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT HỌC SINH' ELSE N'SỔ LIÊN LẠC' END,
        LEFT(N'Học sinh ID: ' + CONVERT(nvarchar(30), src.HocSinhID)
            + N' | Tháng ' + CONVERT(nvarchar(10), p.Thang)
            + N'/' + CONVERT(nvarchar(10), p.Nam), 200),
        CAST(N'__NXT_JSON__' + CASE
            -- C1 dùng bộ cột môn Toán/Tiếng Việt và nhận xét năng lực-phẩm chất.
            WHEN lop.KhoiID BETWEEN 1 AND 5 THEN COALESCE((
                SELECT
                    src.NhanXetToan_HTML AS [Nhận xét môn Toán],
                    src.DiemToan AS [Điểm Toán],
                    src.NhanXetTiengViet_HTML AS [Nhận xét môn Tiếng Việt],
                    src.DiemTiengViet AS [Điểm Tiếng Việt],
                    src.NhanXetMonHocKhac_HTML AS [Nhận xét môn học khác],
                    src.HoatDongGiaoDucKhac_HTML AS [Hoạt động giáo dục khác],
                    src.PhamChatNangLuc_HTML AS [Phẩm chất - Năng lực]
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
            ), N'{}')
            -- C2/C3 đổi bộ cột ở các kỳ tổng kết tháng 12 và tháng 5.
            WHEN p.Thang IN (5, 12) THEN COALESCE((
                SELECT
                    src.UuDiem AS [Ưu điểm],
                    src.NhuocDiem AS [Nhược điểm],
                    src.DeXuat AS [Đề xuất],
                    CASE WHEN p.Thang = 5 THEN src.NhanXetGVCN END AS [Nhận xét ghi học bạ]
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
            ), N'{}')
            -- Các tháng thường ở C2/C3 chỉ có ba trường theo đúng cấu hình Sổ liên lạc.
            ELSE COALESCE((
                SELECT
                    src.NoiDungKienThuc_HTML AS [Về học tập],
                    src.NoiDungNangLuc_HTML AS [Về nền nếp],
                    src.NoiDungHoatDongKhac_HTML AS [Mong muốn phối hợp]
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
            ), N'{}')
        END AS nvarchar(max)),
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0')
        ),
        NULL,
        COALESCE(src.UpdateTime, src.CreateTime),
        NULL,
        NULL,
        NULL
    FROM dbo.tblNhanXetThang_Lop AS p
    INNER JOIN dbo.tblLop AS lop
        ON TRY_CONVERT(int, lop.LopID) = p.LopID
       AND lop.NienKhoa = p.NienKhoa
    INNER JOIN dbo.tbl_LOG_NhanXetThang AS src
        ON src.Lop_NhanXetThangID = p.Lop_NhanXetThangID
    WHERE p.NienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR lop.KhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR CONVERT(varchar(20), p.LopID) = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END)
      AND (@DateFrom IS NULL OR COALESCE(src.UpdateTime, src.CreateTime) >= @DateFrom)
      AND (@DateTo IS NULL OR COALESCE(src.UpdateTime, src.CreateTime) < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, COALESCE(src.UpdateTime, src.CreateTime)) = @FilterHour);

    INSERT INTO @RawLog
    (
        SourceTable, SourceLabel, AuditID, SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc, TenDong, NoiDungChinhSua,
        GiaTriCu, GiaTriMoi, CreateUser, HoTenUser, CreateTime,
        AuditAction, AuditTabGoc, AuditEvent
    )
    SELECT
        'tbl_LOG_NhanXetThang_Lop',
        N'Lịch sử trạng thái kỳ nhận xét',
        src.BackupID,
        NULL,
        src.NienKhoa,
        lop.KhoiID,
        CONVERT(varchar(20), src.LopID),
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT THÁNG (LMS)' ELSE N'SỔ LIÊN LẠC ĐIỆN TỬ' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'Đánh giá nhận xét tháng LMS' ELSE N'Thông tin sổ liên lạc điện tử' END,
        CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT HỌC SINH' ELSE N'SỔ LIÊN LẠC' END,
        LEFT(N'Tháng ' + CONVERT(nvarchar(10), src.Thang) + N'/' + CONVERT(nvarchar(10), src.Nam), 200),
        CAST(CONCAT(
            N'Tình trạng: ', src.TinhTrang,
            N' | Hiển thị phụ huynh: ', src.Is_HienThiPhuHuynh,
            N' | Đang hiển thị: ', src.Is_Showing,
            N' | Cho phép sử dụng: ', src.Enable,
            CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), src.ReasonReject))), N'') IS NULL
                THEN N'' ELSE N' | Lý do từ chối: ' + CONVERT(nvarchar(max), src.ReasonReject) END
        ) AS nvarchar(max)),
        NULL,
        NULL,
        NULLIF(NULLIF(CONVERT(varchar(50), src.LogUser), ''), '0'),
        NULL,
        src.LogTime,
        NULL,
        NULL,
        NULL
    FROM dbo.tbl_LOG_NhanXetThang_Lop AS src
    INNER JOIN dbo.tblLop AS lop
        ON TRY_CONVERT(int, lop.LopID) = src.LopID
       AND lop.NienKhoa = src.NienKhoa
    WHERE src.NienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR lop.KhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR CONVERT(varchar(20), src.LopID) = @LopID)
      AND (NULLIF(@MaTab, '') IS NULL OR @MaTab = CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END)
      AND (NULLIF(@MaMuc, '') IS NULL OR @MaMuc = CASE WHEN lop.KhoiID BETWEEN 1 AND 5 THEN 'nhan-xet-thang' ELSE 'so-lien-lac' END)
      AND (@DateFrom IS NULL OR src.LogTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.LogTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.LogTime) = @FilterHour);

    -- Chuẩn hóa tên bảng audit về đúng tab/mục nghiệp vụ của module so-gvcn.
    -- AuditTab/AuditEvent của các bảng trực tiếp thường là unknown/unavailable,
    -- nên bảng nguồn + KhốiID là thông tin đáng tin cậy để map C1 và C2/C3.
    ;WITH r AS (SELECT * FROM @RawLog)
    UPDATE r
    SET
        MaTab = CASE
            WHEN r.SourceTable IN ('tblSoGVCNKeHoachThang_Log', 'tblSoGVCNKeHoachTuan_Log')
                THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'cong-tac-cn' ELSE 'ke-hoach' END
            WHEN r.SourceTable = 'tblSoGVCNChiTieu_Log' THEN 'chi-tieu'
            WHEN r.SourceTable IN ('tblSoGVCNHuongNghiep_Log') THEN 'huong-nghiep'
            WHEN r.SourceTable IN ('tblSoGVCNKeHoachNamHoc_Log', 'tblSoGVCNKeHoachNamHocChiTieu_Log', 'tblSoGVCNKeHoachNamHocThongKeLop_Log') THEN 'ke-hoach-nam-hoc'
            WHEN r.SourceTable = 'tblSoGVCNHocSinhCanQuanTam_Log' THEN 'hs-can-quan-tam'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiRenLuyen_Log' THEN 'ren-luyen'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiPhuHuynhHop_Log' THEN 'so-lien-lac'
            WHEN r.SourceTable = 'tblSoGVCNNoiDungHopPHHS_Log' THEN 'noi-dung-hop-ph'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiThanhTichHocSinh_Log' THEN 'theo-doi-thanh-tich'
            WHEN r.SourceTable = 'tblSoGVCNThongKeDoTuoi_Log' THEN 'thong-ke-do-tuoi'
            WHEN r.SourceTable = 'tblSoGVCNSiSo_Log' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'theo-doi-si-so' ELSE 'chi-tieu' END
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiSiSoThang_Log' THEN 'theo-doi-si-so'
            WHEN r.SourceTable = 'tblSoGVCNSoKetHKI_Log' THEN 'so-ket-hk1'
            WHEN r.SourceTable = 'tblSoGVCNSoKetHKIDanhGia_Log' THEN 'so-ket-hk1'
            WHEN r.SourceTable = 'tblSoGVCNTongKetNamDanhGia_Log' THEN 'tong-ket-nam'
            WHEN r.SourceTable = 'tblSoGVCNTongKetNamHocC1_Log' THEN 'tong-ket-nam'
            WHEN r.SourceTable IN ('tblSoGVCNBanDaiDienCMHS_Log', 'tblSoGVCNCanBoLop_Log') THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'to-chuc-lop' ELSE 'chi-tieu' END
            WHEN r.SourceTable = 'tblSoGVCNToNhomHocSinh_Log' THEN 'to-chuc-lop'
            WHEN r.SourceTable = 'tblSoGVCN_Log' THEN 'tong-quan-so-gvcn'
            WHEN r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'to-chuc-lop' ELSE 'chi-tieu' END
            ELSE r.MaTab
        END,
        MaMuc = CASE
            WHEN r.SourceTable = 'tblSoGVCNKeHoachThang_Log' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'ke-hoach-thang' ELSE 'ke-hoach' END
            WHEN r.SourceTable = 'tblSoGVCNKeHoachTuan_Log' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN 'ke-hoach-tuan' ELSE 'ke-hoach' END
            WHEN r.SourceTable = 'tblSoGVCNChiTieu_Log' THEN CASE (
                SELECT src.LoaiChiTieu FROM dbo.tblSoGVCNChiTieu_Log AS src WHERE src.AuditID = r.AuditID
            )
                WHEN 'DANH_HIEU' THEN 'danh-hieu'
                WHEN 'PHONG_TRAO' THEN 'hoat-dong-phong-trao'
                ELSE 'chi-tieu-giao-duc'
            END
            WHEN r.SourceTable = 'tblSoGVCNHuongNghiep_Log' THEN 'huong-nghiep'
            WHEN r.SourceTable = 'tblSoGVCNKeHoachNamHoc_Log' THEN 'thuan-loi-kho-khan'
            WHEN r.SourceTable = 'tblSoGVCNKeHoachNamHocChiTieu_Log' THEN 'duy-tri-so-luong'
            WHEN r.SourceTable = 'tblSoGVCNKeHoachNamHocThongKeLop_Log' THEN 'thong-ke-tinh-hinh'
            WHEN r.SourceTable = 'tblSoGVCNHocSinhCanQuanTam_Log' THEN 'hs-can-quan-tam'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiRenLuyen_Log' THEN 'ren-luyen'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiPhuHuynhHop_Log' THEN 'so-lien-lac'
            WHEN r.SourceTable = 'tblSoGVCNNoiDungHopPHHS_Log' THEN 'noi-dung-hop-ph'
            WHEN r.SourceTable = 'tblSoGVCNTheoDoiThanhTichHocSinh_Log' THEN 'theo-doi-thanh-tich'
            WHEN r.SourceTable = 'tblSoGVCNThongKeDoTuoi_Log' THEN 'thong-ke-do-tuoi'
            WHEN r.SourceTable IN ('tblSoGVCNSiSo_Log', 'tblSoGVCNTheoDoiSiSoThang_Log') THEN 'theo-doi-si-so'
            WHEN r.SourceTable = 'tblSoGVCNSoKetHKI_Log' THEN 'ket-qua-hk1'
            WHEN r.SourceTable = 'tblSoGVCNSoKetHKIDanhGia_Log' THEN 'nang-luc-pham-chat'
            WHEN r.SourceTable = 'tblSoGVCNTongKetNamDanhGia_Log' THEN 'danh-gia-tong-quan'
            WHEN r.SourceTable = 'tblSoGVCNTongKetNamHocC1_Log' THEN 'khen-thuong-hoan-thanh'
            WHEN r.SourceTable = 'tblSoGVCNBanDaiDienCMHS_Log' THEN 'ban-dai-dien-cmhs'
            WHEN r.SourceTable = 'tblSoGVCNCanBoLop_Log' THEN 'can-bo-lop'
            WHEN r.SourceTable = 'tblSoGVCNToNhomHocSinh_Log' THEN 'to-nhom-hoc-sinh'
            WHEN r.SourceTable = 'tblSoGVCN_Log' THEN 'tong-quan-so-gvcn'
            WHEN r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log' THEN 'giao-vien-bo-mon'
            ELSE r.MaMuc
        END
    

    -- Đồng nhất nhãn hiển thị với cấu hình thật của uc-main-layout trong module so-gvcn.
    ;WITH r AS (SELECT * FROM @RawLog)
    UPDATE r
    SET
        TenTab = CASE
            WHEN r.MaTab = 'tong-quan-so-gvcn' THEN N'TỔNG QUAN SỔ GVCN'
            WHEN r.MaTab = 'du-lieu-hs' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN N'THÔNG TIN HS LỚP' ELSE N'DỮ LIỆU HS LỚP' END
            WHEN r.MaTab = 'to-chuc-lop' THEN N'TỔ CHỨC LỚP'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' THEN N'KH CHỦ NHIỆM NĂM HỌC'
            WHEN r.MaTab = 'cong-tac-cn' THEN N'CÔNG TÁC CHỦ NHIỆM THÁNG'
            WHEN r.MaTab = 'hs-can-quan-tam' THEN N'HS CẦN QUAN TÂM'
            WHEN r.MaTab = 'ren-luyen' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT THÁNG (LMS)' ELSE N'HỒ SƠ THEO DÕI QTRL' END
            WHEN r.MaTab = 'chi-tieu' THEN N'XD CHỈ TIÊU & GIẢI PHÁP'
            WHEN r.MaTab = 'ke-hoach' THEN N'KH GD THÁNG - TUẦN'
            WHEN r.MaTab = 'so-lien-lac' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN N'THEO DÕI PHỤ HUYNH ĐI HỌP' ELSE N'SỔ LIÊN LẠC ĐIỆN TỬ' END
            WHEN r.MaTab = 'huong-nghiep' THEN N'HƯỚNG NGHIỆP'
            WHEN r.MaTab = 'so-ket-hk1' THEN N'SƠ KẾT HKI'
            WHEN r.MaTab = 'tong-ket-nam' THEN N'TỔNG KẾT NĂM HỌC'
            WHEN r.MaTab = 'theo-doi-si-so' THEN N'THEO DÕI SĨ SỐ HS THEO THÁNG'
            WHEN r.MaTab = 'thong-ke-do-tuoi' THEN N'THỐNG KÊ ĐỘ TUỔI HS'
            WHEN r.MaTab = 'theo-doi-thanh-tich' THEN N'THEO DÕI THÀNH TÍCH HS'
            WHEN r.MaTab = 'noi-dung-hop-ph' THEN N'NỘI DUNG HỌP PHHS'
            ELSE r.TenTab
        END,
        TenMuc = CASE
            WHEN r.MaTab = 'tong-quan-so-gvcn' THEN N'Bản ghi tổng quan Sổ GVCN'
            WHEN r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN N'Danh sách giáo viên bộ môn' ELSE N'III. DANH SÁCH GIÁO VIÊN BỘ MÔN' END
            WHEN r.MaTab = 'cong-tac-cn' AND r.MaMuc = 'ke-hoach-thang' THEN N'Kế hoạch trọng tâm tháng'
            WHEN r.MaTab = 'cong-tac-cn' AND r.MaMuc = 'ke-hoach-tuan' THEN N'Kế hoạch từng tuần'
            WHEN r.MaTab = 'ke-hoach' THEN N'Kế hoạch giáo dục tháng - tuần'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'chi-tieu-giao-duc' THEN N'I. Chỉ tiêu 2 mặt giáo dục'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'danh-hieu' THEN N'DANH HIỆU'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'hoat-dong-phong-trao' THEN N'THAM GIA CÁC HOẠT ĐỘNG PHONG TRÀO KHÁC'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'theo-doi-si-so' THEN N'II. THEO DÕI SĨ SỐ'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'giao-vien-bo-mon' THEN N'III. DANH SÁCH GIÁO VIÊN BỘ MÔN'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'ban-dai-dien-cmhs' THEN N'IV. DANH SÁCH BAN ĐẠI DIỆN CHA MẸ HỌC SINH'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'can-bo-lop' THEN N'V. DANH SÁCH CÁN BỘ LỚP'
            WHEN r.MaTab = 'chi-tieu' THEN N'Xây dựng chỉ tiêu & giải pháp'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' AND r.MaMuc = 'thong-ke-tinh-hinh' THEN N'1. Thống kê tình hình lớp học'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' AND r.MaMuc = 'thuan-loi-kho-khan' THEN N'2. Thuận lợi & 3. Khó khăn'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' AND r.MaMuc = 'duy-tri-so-luong' THEN N'1. Duy trì số lượng'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' AND r.MaMuc = 'chat-luong-giao-duc' THEN N'2. Chất lượng giáo dục'
            WHEN r.MaTab = 'to-chuc-lop' AND r.MaMuc = 'can-bo-lop' THEN N'Cán bộ lớp'
            WHEN r.MaTab = 'to-chuc-lop' AND r.MaMuc = 'ban-dai-dien-cmhs' THEN N'Ban đại diện CMHS'
            WHEN r.MaTab = 'to-chuc-lop' AND r.MaMuc = 'to-nhom-hoc-sinh' THEN N'Phân chia tổ/nhóm'
            WHEN r.MaTab = 'so-ket-hk1' AND r.MaMuc = 'cong-tac-duy-tri' THEN N'1. Công tác duy trì số lượng'
            WHEN r.MaTab = 'so-ket-hk1' AND r.MaMuc = 'nang-luc-pham-chat' THEN N'2. Về năng lực, phẩm chất'
            WHEN r.MaTab = 'so-ket-hk1' AND r.MaMuc = 'ket-qua-hk1' THEN N'Kết quả học kì I'
            WHEN r.MaTab = 'tong-ket-nam' AND r.MaMuc = 'danh-gia-tong-quan' THEN N'Đánh giá tổng quan'
            WHEN r.MaTab = 'tong-ket-nam' AND r.MaMuc = 'khen-thuong-hoan-thanh' THEN N'Khen thưởng và hoàn thành CT'
            WHEN r.MaTab = 'hs-can-quan-tam' THEN N'Hồ sơ học sinh cần quan tâm'
            WHEN r.MaTab = 'ren-luyen' THEN N'Theo dõi quá trình rèn luyện'
            WHEN r.MaTab = 'so-lien-lac' AND r.SourceTable IN ('tbl_LOG_NhanXetThang', 'tbl_LOG_NhanXetThang_Lop') THEN N'Thông tin sổ liên lạc điện tử'
            WHEN r.MaTab = 'so-lien-lac' THEN N'Theo dõi phụ huynh đi họp'
            WHEN r.MaTab = 'noi-dung-hop-ph' THEN N'Nội dung họp phụ huynh học sinh'
            WHEN r.MaTab = 'theo-doi-si-so' THEN N'Biến động sĩ số học sinh'
            WHEN r.MaTab = 'thong-ke-do-tuoi' THEN N'Thống kê độ tuổi theo năm sinh'
            WHEN r.MaTab = 'theo-doi-thanh-tich' THEN N'Theo dõi thành tích học sinh'
            WHEN r.MaTab = 'huong-nghiep' THEN N'Tư vấn và giáo dục hướng nghiệp'
            ELSE r.TenMuc
        END,
        NhomMuc = CASE
            WHEN r.MaTab = 'tong-quan-so-gvcn' THEN N'TỔNG QUAN'
            WHEN r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log' AND r.KhoiID BETWEEN 1 AND 5 THEN N'DANH SÁCH GIÁO VIÊN BỘ MÔN'
            WHEN r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log' THEN N'III. DANH SÁCH GIÁO VIÊN BỘ MÔN'
            WHEN r.MaTab = 'du-lieu-hs' THEN CASE WHEN r.KhoiID BETWEEN 1 AND 5 THEN N'THÔNG TIN HỌC SINH' ELSE N'DỮ LIỆU HỌC SINH' END
            WHEN r.MaTab = 'to-chuc-lop' THEN N'TỔ CHỨC LỚP HỌC'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' AND r.MaMuc IN ('thong-ke-tinh-hinh', 'thuan-loi-kho-khan') THEN N'I. ĐẶC ĐIỂM TÌNH HÌNH'
            WHEN r.MaTab = 'ke-hoach-nam-hoc' THEN N'II. NỘI DUNG KẾ HOẠCH'
            WHEN r.MaTab = 'cong-tac-cn' THEN N'CÔNG TÁC CHỦ NHIỆM'
            WHEN r.MaTab = 'hs-can-quan-tam' THEN N'THEO DÕI HỌC SINH'
            WHEN r.MaTab = 'ren-luyen' THEN N'RÈN LUYỆN'
            WHEN r.SourceTable IN ('tbl_LOG_NhanXetThang', 'tbl_LOG_NhanXetThang_Lop') AND r.KhoiID BETWEEN 1 AND 5 THEN N'NHẬN XÉT HỌC SINH'
            WHEN r.SourceTable IN ('tbl_LOG_NhanXetThang', 'tbl_LOG_NhanXetThang_Lop') THEN N'SỔ LIÊN LẠC'
            WHEN r.MaTab = 'so-lien-lac' THEN N'THEO DÕI PHỤ HUYNH'
            WHEN r.MaTab = 'noi-dung-hop-ph' THEN N'NỘI DUNG HỌP PHHS'
            WHEN r.MaTab = 'theo-doi-si-so' THEN N'THEO DÕI SĨ SỐ'
            WHEN r.MaTab = 'thong-ke-do-tuoi' THEN N'THỐNG KÊ ĐỘ TUỔI'
            WHEN r.MaTab = 'theo-doi-thanh-tich' THEN N'THEO DÕI THÀNH TÍCH'
            WHEN r.MaTab = 'huong-nghiep' THEN N'HƯỚNG NGHIỆP'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc IN ('chi-tieu-giao-duc', 'danh-hieu', 'hoat-dong-phong-trao') THEN N'CHỈ TIÊU & GIẢI PHÁP'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'theo-doi-si-so' THEN N'II. THEO DÕI SĨ SỐ'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'giao-vien-bo-mon' THEN N'III. DANH SÁCH GIÁO VIÊN BỘ MÔN'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'ban-dai-dien-cmhs' THEN N'IV. DANH SÁCH BAN ĐẠI DIỆN CHA MẸ HỌC SINH'
            WHEN r.MaTab = 'chi-tieu' AND r.MaMuc = 'can-bo-lop' THEN N'V. DANH SÁCH CÁN BỘ LỚP'
            WHEN r.MaTab = 'chi-tieu' THEN N'CHỈ TIÊU & GIẢI PHÁP'
            WHEN r.MaTab = 'ke-hoach' THEN N'KẾ HOẠCH'
            WHEN r.MaTab = 'so-ket-hk1' THEN N'ĐÁNH GIÁ HOẠT ĐỘNG LỚP'
            WHEN r.MaTab = 'tong-ket-nam' THEN N'ĐÁNH GIÁ TỔNG QUAN'
            ELSE r.NhomMuc
        END;
    /*
       Các bảng *_Log lưu snapshot dữ liệu tại thời điểm audit, không chỉ lưu mã audit.
       Sau khi gom 24 nguồn vào @RawLog, bổ sung tóm tắt nghiệp vụ từ snapshot đó
       để màn hình trả lời được "đã cập nhật nội dung gì". Đây là giá trị ghi nhận sau
       thao tác; các bảng hiện tại không có cặp old/new đồng nhất để tính diff tuyệt đối.
    */
    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Trạng thái: ', LEFT(CONVERT(nvarchar(max), src.TrangThai), 250),
        N' | Thông tin lớp: ', LEFT(CONVERT(nvarchar(max), src.ThongTinLop), 400),
        N' | Chỉ tiêu: ', LEFT(CONVERT(nvarchar(max), src.ChiTieu), 400),
        N' | Sĩ số: ', LEFT(CONVERT(nvarchar(max), src.SiSo), 150)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCN_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCN_Log';

    UPDATE r SET NoiDungChinhSua = CASE
        WHEN src.AuditKhoiID BETWEEN 1 AND 5 THEN CONCAT(
            N'STT: ', CONVERT(nvarchar(30), src.STT),
            N' | Mã học sinh: ', COALESCE(NULLIF(src.MaHocSinh, ''), CONVERT(nvarchar(30), src.HocSinhID)),
            N' | Học sinh: ', LEFT(CONVERT(nvarchar(max), src.HocSinh), 250),
            N' | Cha/mẹ: ', LEFT(CONVERT(nvarchar(max), src.ChaMe), 250),
            N' | Nhiệm vụ: ', LEFT(CONVERT(nvarchar(max), src.NhiemVu), 250),
            N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 300)
        )
        ELSE CONCAT(
            N'STT: ', CONVERT(nvarchar(30), src.STT),
            N' | Mã học sinh: ', COALESCE(NULLIF(src.MaHocSinh, ''), CONVERT(nvarchar(30), src.HocSinhID)),
            N' | Học sinh: ', LEFT(CONVERT(nvarchar(max), src.HocSinh), 250),
            N' | Cha/mẹ: ', LEFT(CONVERT(nvarchar(max), src.ChaMe), 250),
            N' | Nghề nghiệp: ', LEFT(CONVERT(nvarchar(max), src.NgheNghiep), 250),
            N' | Điện thoại: ', LEFT(CONVERT(nvarchar(max), src.DienThoai), 100),
            N' | Nhiệm vụ: ', LEFT(CONVERT(nvarchar(max), src.NhiemVu), 250)
        ) END
    FROM @RawLog AS r JOIN dbo.tblSoGVCNBanDaiDienCMHS_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNBanDaiDienCMHS_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'STT: ', CONVERT(nvarchar(30), src.STT),
        N' | Mã học sinh: ', COALESCE(NULLIF(src.MaHocSinh, ''), CONVERT(nvarchar(30), src.HocSinhID)),
        N' | Học sinh: ', LEFT(CONVERT(nvarchar(max), src.HocSinh), 250),
        N' | Chức vụ: ', LEFT(CONVERT(nvarchar(max), src.ChucVu), 250),
        N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 300)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNCanBoLop_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNCanBoLop_Log';

    UPDATE r SET NoiDungChinhSua = CASE src.LoaiChiTieu
        WHEN 'GIAO_DUC' THEN CONCAT(
            N'Dòng: ', CONVERT(nvarchar(30), src.RowIndex),
            N' | Mặt giáo dục: ', LEFT(CONVERT(nvarchar(max), src.MatGiaoDuc), 200),
            N' | Yêu cầu cần đạt: ', LEFT(CONVERT(nvarchar(max), src.YeuCau), 400),
            N' | Tốt: ', CONVERT(nvarchar(60), src.Tot),
            N' | Khá: ', CONVERT(nvarchar(60), src.Kha),
            N' | Đạt: ', CONVERT(nvarchar(60), src.Dat),
            N' | Chưa đạt: ', CONVERT(nvarchar(60), src.ChuaDat),
            N' | Biện pháp: ', LEFT(CONVERT(nvarchar(max), src.BienPhap), 500)
        )
        WHEN 'DANH_HIEU' THEN CONCAT(
            N'Dòng: ', CONVERT(nvarchar(30), src.RowIndex),
            N' | Yêu cầu cần đạt: ', LEFT(CONVERT(nvarchar(max), src.YeuCau), 400),
            N' | HSXS: ', CONVERT(nvarchar(60), src.HSXS),
            N' | HSG: ', CONVERT(nvarchar(60), src.HSG),
            N' | Ghi chú / biện pháp: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 400)
        )
        WHEN 'PHONG_TRAO' THEN CONCAT(
            N'Dòng: ', CONVERT(nvarchar(30), src.RowIndex),
            N' | Yêu cầu cần đạt: ', LEFT(CONVERT(nvarchar(max), src.YeuCau), 400),
            N' | Nội dung: ', LEFT(CONVERT(nvarchar(max), src.NoiDung), 500),
            N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 400)
        )
        ELSE CONCAT(
            N'Loại chỉ tiêu: ', LEFT(CONVERT(nvarchar(max), src.LoaiChiTieu), 100),
            N' | Nội dung: ', LEFT(CONVERT(nvarchar(max), src.NoiDung), 500),
            N' | Yêu cầu: ', LEFT(CONVERT(nvarchar(max), src.YeuCau), 400),
            N' | Biện pháp: ', LEFT(CONVERT(nvarchar(max), src.BienPhap), 500),
            N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 300)
        ) END
    FROM @RawLog AS r JOIN dbo.tblSoGVCNChiTieu_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNChiTieu_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Bộ môn: ', LEFT(CONVERT(nvarchar(max), src.BoMon), 250),
        N' | Học kỳ: ', LEFT(CONVERT(nvarchar(max), src.HocKy), 100),
        N' | Giáo viên: ', LEFT(CONVERT(nvarchar(max), src.GiaoVien), 250),
        N' | Thay đổi: ', LEFT(CONVERT(nvarchar(max), src.ThayDoi), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNGiaoVienBoMon_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNGiaoVienBoMon_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Học sinh ID: ', CONVERT(nvarchar(30), src.HocSinhID),
        N' | Tháng 8: ', LEFT(CONVERT(nvarchar(max), src.Thang8), 250),
        N' | Tháng 9: ', LEFT(CONVERT(nvarchar(max), src.Thang9), 250),
        N' | Nhận xét HKI: ', LEFT(CONVERT(nvarchar(max), src.NhanXetHKI), 500),
        N' | Kết quả HKI: ', LEFT(CONVERT(nvarchar(max), src.KetQuaHKI), 250)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNHocSinhCanQuanTam_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNHocSinhCanQuanTam_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Học sinh: ', LEFT(CONVERT(nvarchar(max), src.HoTen), 250),
        N' | Môn thi tốt nghiệp: ', LEFT(CONVERT(nvarchar(max), src.MonThiTN), 250),
        N' | Kết quả trắc nghiệm: ', LEFT(CONVERT(nvarchar(max), src.KQTracNghiem), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNHuongNghiep_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNHuongNghiep_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Nội dung kế hoạch năm học: ', LEFT(CONVERT(nvarchar(max), src.JsonData), 1200)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNKeHoachNamHoc_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNKeHoachNamHoc_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Môn học ID: ', CONVERT(nvarchar(30), src.MonHocID),
        N' | Tốt: ', CONVERT(nvarchar(60), src.Tot_SoLuong), N' (', CONVERT(nvarchar(60), src.Tot_TiLe), N'%)',
        N' | Đạt: ', CONVERT(nvarchar(60), src.Dat_SoLuong), N' (', CONVERT(nvarchar(60), src.Dat_TiLe), N'%)',
        N' | Cần cố gắng: ', CONVERT(nvarchar(60), src.CanCoGang_SoLuong), N' (', CONVERT(nvarchar(60), src.CanCoGang_TiLe), N'%)'
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNKeHoachNamHocChiTieu_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNKeHoachNamHocChiTieu_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Thời điểm: ', LEFT(CONVERT(nvarchar(max), src.ThoiDiem), 150),
        N' | Tổng số: ', CONVERT(nvarchar(60), src.TongSo),
        N' | Nữ: ', CONVERT(nvarchar(60), src.Nu),
        N' | Dân tộc: ', CONVERT(nvarchar(60), src.DanToc),
        N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 400)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNKeHoachNamHocThongKeLop_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNKeHoachNamHocThongKeLop_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Tháng ', CONVERT(nvarchar(20), src.Thang),
        CASE WHEN LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.ChuDe), N'[', N''), N']', N''), N'"', N''), N',', N''), N' ', N'')) > 0
            THEN N' | Chủ đề: ' + LEFT(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.ChuDe), N'["', N''), N'"]', N''), N'","', N' • '), 800) ELSE N'' END,
        CASE WHEN LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.MucTieu), N'[', N''), N']', N''), N'"', N''), N',', N''), N' ', N'')) > 0
            THEN N' | Mục tiêu: ' + LEFT(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.MucTieu), N'["', N''), N'"]', N''), N'","', N' • '), 800) ELSE N'' END,
        CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), src.NhiemVu))), N'') IS NOT NULL
            THEN N' | Nhiệm vụ: ' + LEFT(CONVERT(nvarchar(max), src.NhiemVu), 600) ELSE N'' END,
        CASE WHEN NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), src.DanhGia))), N'') IS NOT NULL
            THEN N' | Đánh giá: ' + LEFT(CONVERT(nvarchar(max), src.DanhGia), 800) ELSE N'' END,
        CASE WHEN
            LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.ChuDe), N'[', N''), N']', N''), N'"', N''), N',', N''), N' ', N'')) = 0
            AND LEN(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar(max), src.MucTieu), N'[', N''), N']', N''), N'"', N''), N',', N''), N' ', N'')) = 0
            AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), src.NhiemVu))), N'') IS NULL
            AND NULLIF(LTRIM(RTRIM(CONVERT(nvarchar(max), src.DanhGia))), N'') IS NULL
            THEN N' | Chưa nhập nội dung nghiệp vụ' ELSE N'' END
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNKeHoachThang_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNKeHoachThang_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Tuần ', CONVERT(nvarchar(20), src.TuanTrongThang),
        N' | Từ ', CONVERT(nvarchar(10), src.TuNgay, 103), N' đến ', CONVERT(nvarchar(10), src.DenNgay, 103),
        N' | Kế hoạch thực hiện: ', LEFT(CONVERT(nvarchar(max), src.KeHoachThucHien), 900),
        N' | Kết quả: ', LEFT(CONVERT(nvarchar(max), src.KetQua), 500),
        N' | Nguyên nhân: ', LEFT(CONVERT(nvarchar(max), src.NguyenNhan), 400)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNKeHoachTuan_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNKeHoachTuan_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Đợt họp: ', LEFT(CONVERT(nvarchar(max), src.DotHop), 200),
        N' | Thời gian: ', LEFT(CONVERT(nvarchar(max), src.ThoiGian), 150),
        N' | Địa điểm: ', LEFT(CONVERT(nvarchar(max), src.DiaDiem), 200),
        N' | Nội dung: ', LEFT(CONVERT(nvarchar(max), src.NoiDungChinh), 600),
        N' | Kết luận: ', LEFT(CONVERT(nvarchar(max), src.KetLuan), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNNoiDungHopPHHS_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNNoiDungHopPHHS_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Mốc: ', LEFT(CONVERT(nvarchar(max), src.Moc), 200),
        N' | Sĩ số: ', CONVERT(nvarchar(60), src.SiSo),
        N' | Nam: ', CONVERT(nvarchar(60), src.Nam),
        N' | Chuyển đi: ', CONVERT(nvarchar(60), src.ChuyenDi),
        N' | Chuyển đến: ', CONVERT(nvarchar(60), src.ChuyenDen)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNSiSo_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNSiSo_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Nội dung sơ kết học kỳ I: ', LEFT(CONVERT(nvarchar(max), src.JsonData), 1200)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNSoKetHKI_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNSoKetHKI_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Loại đánh giá: ', LEFT(CONVERT(nvarchar(max), src.LoaiDanhGia), 200),
        N' | Tiêu chí: ', LEFT(CONVERT(nvarchar(max), src.TenTieuChi), 300),
        N' | Mức xếp loại: ', LEFT(CONVERT(nvarchar(max), src.MucXepLoaiCode), 150),
        N' | Số lượng: ', CONVERT(nvarchar(60), src.SoLuong),
        N' | Tỷ lệ: ', CONVERT(nvarchar(60), src.TiLe)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNSoKetHKIDanhGia_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNSoKetHKIDanhGia_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Học sinh ID: ', CONVERT(nvarchar(30), src.HocSinhID),
        N' | Lần 1: ', LEFT(CONVERT(nvarchar(max), src.Lan1), 300),
        N' | Lần 2: ', LEFT(CONVERT(nvarchar(max), src.Lan2), 300),
        N' | Lần 3: ', LEFT(CONVERT(nvarchar(max), src.Lan3), 300),
        N' | Ghi chú: ', LEFT(CONVERT(nvarchar(max), src.GhiChu), 300)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTheoDoiPhuHuynhHop_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTheoDoiPhuHuynhHop_Log';

    -- QTRL dùng mã Thang cho cả tháng thực tế và các cột tổng hợp cuối kỳ;
    -- hiển thị nhãn nghiệp vụ để không biến mã 92-96 thành "Tháng 92-96".
    UPDATE r SET NoiDungChinhSua = CONCAT(
        CASE src.Thang
            WHEN 0 THEN N'Học sinh cần hỗ trợ đặc biệt'
            WHEN 99 THEN N'Ban cán sự'
            WHEN 91 THEN N'Nhận xét học kỳ I'
            WHEN 81 THEN N'Kết quả rèn luyện học kỳ I'
            WHEN 82 THEN N'Kết quả học tập học kỳ I'
            WHEN 92 THEN N'Nhận xét học kỳ II'
            WHEN 93 THEN N'Kết quả rèn luyện học kỳ II'
            WHEN 94 THEN N'Kết quả học tập học kỳ II'
            WHEN 95 THEN N'Danh hiệu'
            WHEN 96 THEN N'Thành tích khác'
            ELSE N'Tháng ' + CONVERT(nvarchar(20), src.Thang)
        END,
        N' | Nội dung: ', LEFT(CONVERT(nvarchar(max), src.NoiDung), 600),
        N' | Biện pháp: ', LEFT(CONVERT(nvarchar(max), src.BienPhap), 500),
        N' | Kết quả: ', LEFT(CONVERT(nvarchar(max), src.KetQua), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTheoDoiRenLuyen_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTheoDoiRenLuyen_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Thời điểm: ', LEFT(CONVERT(nvarchar(max), src.ThoiDiem), 150),
        N' | Tổng số: ', CONVERT(nvarchar(60), src.TongSo),
        N' | Nữ: ', CONVERT(nvarchar(60), src.Nu),
        N' | Đội viên: ', CONVERT(nvarchar(60), src.DoiVien),
        N' | Nhi đồng: ', CONVERT(nvarchar(60), src.NhiDong),
        N' | Tăng/giảm: ', LEFT(CONVERT(nvarchar(max), src.TangGiamLiDo), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTheoDoiSiSoThang_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTheoDoiSiSoThang_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Học sinh ID: ', CONVERT(nvarchar(30), src.HocSinhID),
        N' | Học kỳ I: ', LEFT(CONVERT(nvarchar(max), src.HKI), 500),
        N' | Cuối năm: ', LEFT(CONVERT(nvarchar(max), src.CuoiNam), 500)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTheoDoiThanhTichHocSinh_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTheoDoiThanhTichHocSinh_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Độ tuổi: ', LEFT(CONVERT(nvarchar(max), src.AgeLabel), 150),
        N' | Nam: ', CONVERT(nvarchar(60), src.Nam),
        N' | Nữ: ', CONVERT(nvarchar(60), src.Nu),
        N' | Khuyết tật: ', CONVERT(nvarchar(60), src.KhuyetTat)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNThongKeDoTuoi_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNThongKeDoTuoi_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Loại đánh giá: ', LEFT(CONVERT(nvarchar(max), src.LoaiDanhGia), 200),
        N' | Tiêu chí: ', LEFT(CONVERT(nvarchar(max), src.TenTieuChi), 300),
        N' | Mức xếp loại: ', LEFT(CONVERT(nvarchar(max), src.MucXepLoaiCode), 150),
        N' | Số lượng: ', CONVERT(nvarchar(60), src.SoLuong),
        N' | Tỷ lệ: ', CONVERT(nvarchar(60), src.TiLe),
        N' | Kỳ đánh giá: ', LEFT(CONVERT(nvarchar(max), src.KyDanhGia), 100)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTongKetNamDanhGia_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTongKetNamDanhGia_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Duy trì số lượng: ', LEFT(CONVERT(nvarchar(max), src.DuyTriSoLuong), 300),
        N' | Năng lực/phẩm chất: ', LEFT(CONVERT(nvarchar(max), src.NangLucPhamChat), 500),
        N' | Kiến thức/kỹ năng: ', LEFT(CONVERT(nvarchar(max), src.KienThucKyNang), 500),
        N' | Hoàn thành chương trình: ', LEFT(CONVERT(nvarchar(max), src.HoanThanhCT), 300),
        N' | Phong trào khác: ', LEFT(CONVERT(nvarchar(max), src.PhongTraoKhac), 300)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNTongKetNamHocC1_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNTongKetNamHocC1_Log';

    UPDATE r SET NoiDungChinhSua = CONCAT(
        N'Học sinh: ', LEFT(CONVERT(nvarchar(max), src.HocSinh), 250),
        N' | Tổ: ', LEFT(CONVERT(nvarchar(max), src.ToNhom), 200),
        N' | Nhiệm vụ: ', LEFT(CONVERT(nvarchar(max), src.NhiemVu), 400),
        N' | Bàn: ', LEFT(CONVERT(nvarchar(max), src.Ban), 100)
    ) FROM @RawLog AS r JOIN dbo.tblSoGVCNToNhomHocSinh_Log AS src ON src.AuditID = r.AuditID
    WHERE r.SourceTable = 'tblSoGVCNToNhomHocSinh_Log';

    SELECT
        r.AuditID AS LogID,
        r.SoGVCNID,
        r.NienKhoa,
        r.KhoiID,
        r.LopID,
        r.MaTab,
        r.TenTab,
        r.MaMuc,
        r.TenMuc,
        r.NhomMuc,
        r.TenDong,
        r.NoiDungChinhSua,
        r.GiaTriCu,
        r.GiaTriMoi,
        r.CreateUser,
        COALESCE(
            NULLIF(r.HoTenUser, 'unknown/unavailable'),
            NULLIF(LTRIM(RTRIM(ISNULL(gv.HoGV, N'') + N' ' + ISNULL(gv.TenGV, N''))), N''),
            NULLIF(r.CreateUser, 'unknown/unavailable')
        ) AS HoTenUser,
        r.CreateTime,
        r.SourceTable AS NguonBang,
        r.AuditAction,
        r.AuditTabGoc,
        r.AuditEvent,
        CONVERT(VARCHAR(19), r.CreateTime, 120) AS CreateTimeString
    FROM @RawLog AS r
    LEFT JOIN dbo.tblGiaoVien AS gv ON gv.GiaoVienID = r.CreateUser
    WHERE (NULLIF(@LopID, '') IS NULL OR r.LopID = @LopID)
      AND r.MaTab = @MaTab
      AND (NULLIF(@MaMuc, '') IS NULL OR r.MaMuc = @MaMuc)
    ORDER BY r.CreateTime DESC, r.AuditID DESC;
END;
