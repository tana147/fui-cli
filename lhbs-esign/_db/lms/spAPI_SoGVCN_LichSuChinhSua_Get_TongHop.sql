CREATE   PROCEDURE dbo.spAPI_SoGVCN_LichSuChinhSua_Get_TongHop

    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(20),
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
    -- Summary chỉ cần khóa phân nhóm, thời gian và người sửa gần nhất.
    -- Nội dung thay đổi được đọc riêng bởi SP chi tiết, nên các cột payload bên
    -- dưới được để NULL để tránh đọc/copy các cột nvarchar(max) từ 24 bảng log.
    DECLARE @RawLog TABLE
    (
        SourceTable varchar(128) NOT NULL,
        SourceLabel nvarchar(200) NULL,
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
        TenDong nvarchar(1) NULL,
        NoiDungChinhSua nvarchar(1) NULL,
        GiaTriCu nvarchar(1) NULL,
        GiaTriMoi nvarchar(1) NULL,
        CreateUser varchar(50) NULL,
        HoTenUser nvarchar(200) NULL,
        CreateTime datetime NULL,
        AuditAction char(1) NULL,
        AuditTabGoc varchar(1) NULL,
        AuditEvent varchar(1) NULL
    );


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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCN_Log',
        N'Tổng quan Sổ GVCN',
        'records',
        N'Tổng quan Sổ GVCN',
        N'tblSoGVCN_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCN_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNBanDaiDienCMHS_Log',
        N'Ban đại diện CMHS',
        'records',
        N'Ban đại diện CMHS',
        N'tblSoGVCNBanDaiDienCMHS_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNBanDaiDienCMHS_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNCanBoLop_Log',
        N'Cán bộ lớp',
        'records',
        N'Cán bộ lớp',
        N'tblSoGVCNCanBoLop_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNCanBoLop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNChiTieu_Log',
        N'Chỉ tiêu',
        'records',
        N'Chỉ tiêu',
        N'tblSoGVCNChiTieu_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNChiTieu_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNGiaoVienBoMon_Log',
        N'Giáo viên bộ môn',
        'records',
        N'Giáo viên bộ môn',
        N'tblSoGVCNGiaoVienBoMon_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNGiaoVienBoMon_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNHocSinhCanQuanTam_Log',
        N'Học sinh cần quan tâm',
        'records',
        N'Học sinh cần quan tâm',
        N'tblSoGVCNHocSinhCanQuanTam_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNHocSinhCanQuanTam_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNHuongNghiep_Log',
        N'Hướng nghiệp',
        'records',
        N'Hướng nghiệp',
        N'tblSoGVCNHuongNghiep_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNHuongNghiep_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHoc_Log',
        N'Kế hoạch năm học',
        'records',
        N'Kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHoc_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHoc_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHocChiTieu_Log',
        N'Chỉ tiêu kế hoạch năm học',
        'records',
        N'Chỉ tiêu kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHocChiTieu_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHocChiTieu_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachNamHocThongKeLop_Log',
        N'Thống kê lớp kế hoạch năm học',
        'records',
        N'Thống kê lớp kế hoạch năm học',
        N'tblSoGVCNKeHoachNamHocThongKeLop_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNKeHoachNamHocThongKeLop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachThang_Log',
        N'Kế hoạch tháng',
        'records',
        N'Kế hoạch tháng',
        N'tblSoGVCNKeHoachThang_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNKeHoachThang_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNKeHoachTuan_Log',
        N'Kế hoạch tuần',
        'records',
        N'Kế hoạch tuần',
        N'tblSoGVCNKeHoachTuan_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNKeHoachTuan_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNNoiDungHopPHHS_Log',
        N'Nội dung họp PHHS',
        'records',
        N'Nội dung họp PHHS',
        N'tblSoGVCNNoiDungHopPHHS_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNNoiDungHopPHHS_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSiSo_Log',
        N'Sĩ số',
        'records',
        N'Sĩ số',
        N'tblSoGVCNSiSo_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNSiSo_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSoKetHKI_Log',
        N'Sơ kết HKI',
        'records',
        N'Sơ kết HKI',
        N'tblSoGVCNSoKetHKI_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNSoKetHKI_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNSoKetHKIDanhGia_Log',
        N'Đánh giá sơ kết HKI',
        'records',
        N'Đánh giá sơ kết HKI',
        N'tblSoGVCNSoKetHKIDanhGia_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNSoKetHKIDanhGia_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiPhuHuynhHop_Log',
        N'Theo dõi phụ huynh đi họp',
        'records',
        N'Theo dõi phụ huynh đi họp',
        N'tblSoGVCNTheoDoiPhuHuynhHop_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiPhuHuynhHop_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiRenLuyen_Log',
        N'Theo dõi rèn luyện',
        'records',
        N'Theo dõi rèn luyện',
        N'tblSoGVCNTheoDoiRenLuyen_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiRenLuyen_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiSiSoThang_Log',
        N'Theo dõi sĩ số tháng',
        'records',
        N'Theo dõi sĩ số tháng',
        N'tblSoGVCNTheoDoiSiSoThang_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiSiSoThang_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTheoDoiThanhTichHocSinh_Log',
        N'Theo dõi thành tích học sinh',
        'records',
        N'Theo dõi thành tích học sinh',
        N'tblSoGVCNTheoDoiThanhTichHocSinh_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTheoDoiThanhTichHocSinh_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNThongKeDoTuoi_Log',
        N'Thống kê độ tuổi',
        'records',
        N'Thống kê độ tuổi',
        N'tblSoGVCNThongKeDoTuoi_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNThongKeDoTuoi_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTongKetNamDanhGia_Log',
        N'Đánh giá tổng kết năm',
        'records',
        N'Đánh giá tổng kết năm',
        N'tblSoGVCNTongKetNamDanhGia_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTongKetNamDanhGia_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNTongKetNamHocC1_Log',
        N'Tổng kết năm học C1',
        'records',
        N'Tổng kết năm học C1',
        N'tblSoGVCNTongKetNamHocC1_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNTongKetNamHocC1_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
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
        NULL AS SoGVCNID,
        NULL AS NienKhoa,
        src.AuditKhoiID,
        src.AuditLopID,
        'log-tblSoGVCNToNhomHocSinh_Log',
        N'Tổ/nhóm học sinh',
        'records',
        N'Tổ/nhóm học sinh',
        N'tblSoGVCNToNhomHocSinh_Log',
        NULL,
        NULL,
        NULL,
        NULL,
        COALESCE(
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.UpdateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(NULLIF(CONVERT(varchar(50), src.CreateUser), ''), '0'), 'unknown/unavailable'),
            NULLIF(NULLIF(CONVERT(varchar(50), src.AuditUser), ''), 'unknown/unavailable')
        ) AS CreateUser,
        NULLIF(src.AuditUserName, 'unknown/unavailable'),
        src.AuditTime,
        NULL AS AuditAction,
        NULL AS AuditTabGoc,
        NULL AS AuditEvent
    FROM dbo.[tblSoGVCNToNhomHocSinh_Log] AS src
    WHERE src.AuditNienKhoa = @NienKhoa
      AND (@KhoiID IS NULL OR @KhoiID = 0 OR src.AuditKhoiID = @KhoiID)
      AND (NULLIF(@LopID, '') IS NULL OR src.AuditLopID = @LopID)
      AND (@DateFrom IS NULL OR src.AuditTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.AuditTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.AuditTime) = @FilterHour);

    -- C1 và C2/C3 đều lưu lịch sử nhận xét tháng trong cùng hai bảng LMS.
    -- Snapshot nội dung không có LogTime riêng; dùng UpdateTime/CreateTime như mốc phiên bản,
    -- còn thay đổi trạng thái kỳ dùng LogTime chính xác từ bảng log trạng thái.
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
        NULL,
        NULL,
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
        NULL,
        NULL,
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
      AND (@DateFrom IS NULL OR src.LogTime >= @DateFrom)
      AND (@DateTo IS NULL OR src.LogTime < DATEADD(DAY, 1, @DateTo))
      AND (@FilterHour IS NULL OR DATEPART(HOUR, src.LogTime) = @FilterHour);

    -- Chuẩn hóa tên bảng audit về đúng tab/mục nghiệp vụ của module so-gvcn.
    -- AuditTab/AuditEvent của các bảng trực tiếp thường là unknown/unavailable,
    -- nên bảng nguồn + KhốiID là thông tin đáng tin cậy để map C1 và C2/C3.
    -- Cập nhật trực tiếp table variable; không dùng UPDATE trên tên CTE r
    -- vì runtime trên DB đã phát sinh lỗi 208 "Invalid object name 'r'".
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
            -- Bảng cha không ghi được tab phát sinh nên để riêng ở nhóm tổng quan.
            WHEN r.SourceTable = 'tblSoGVCN_Log' THEN 'tong-quan-so-gvcn'
            -- Danh sách GVBM nằm trong tab tổ chức lớp ở C1, tab chỉ tiêu ở C2/C3.
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
    FROM @RawLog AS r;
    

    -- Đồng nhất nhãn hiển thị với cấu hình thật của uc-main-layout trong module so-gvcn.
    -- Cập nhật trực tiếp table variable để tránh lỗi runtime khi UPDATE CTE r.
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
        END
    FROM @RawLog AS r;
	;WITH RankedLogs AS
	(
		-- Lấy người sửa mới nhất một lần cho mỗi lớp/tab/mục;
		-- tránh OUTER APPLY quét lại toàn bộ @RawLog cho từng nhóm summary.
		SELECT
			r.LopID,
			r.MaTab,
			r.MaMuc,
			COALESCE(
				NULLIF(r.HoTenUser, 'unknown/unavailable'),
				NULLIF(LTRIM(RTRIM(ISNULL(gv.HoGV, N'') + N' ' + ISNULL(gv.TenGV, N''))), N''),
				NULLIF(r.CreateUser, 'unknown/unavailable')
			) AS HoTenUser,
			ROW_NUMBER() OVER
			(
				PARTITION BY r.LopID, r.MaTab, r.MaMuc
				ORDER BY r.CreateTime DESC, r.AuditID DESC
			) AS LatestRank
		FROM @RawLog AS r
		LEFT JOIN dbo.tblGiaoVien AS gv ON gv.GiaoVienID = r.CreateUser
	)
	SELECT
        r.LopID,
        r.MaTab,
        r.TenTab,
        r.MaMuc,
        r.TenMuc,
        r.NhomMuc,
        COUNT(*) AS SoLanChinhSua,
        MAX(r.CreateTime) AS ThoiGianSuaMoiNhat,
        latest.HoTenUser AS NguoiSuaMoiNhat,
        MAX(r.SourceTable) AS NguonBang
    FROM @RawLog AS r
	LEFT JOIN RankedLogs AS latest
	  ON ISNULL(latest.LopID, '') = ISNULL(r.LopID, '')
	 AND latest.MaTab = r.MaTab
	 AND latest.MaMuc = r.MaMuc
	 AND latest.LatestRank = 1
	GROUP BY r.LopID, r.MaTab, r.TenTab, r.MaMuc, r.TenMuc, r.NhomMuc, latest.HoTenUser
    ORDER BY r.LopID, r.MaTab, MIN(r.AuditID);
END;
