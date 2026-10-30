CREATE PROCEDURE dbo.spAPI_LMS_SyncDiemLog_History_Select
    @CapID INT,
    @KhoiID INT,
    @NienKhoa INT,
    @LopChonID VARCHAR(50),
    @MonHocLopID INT,
    @MonHocID INT,
    @TemplateBangDiemID INT,
    @HocKy TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    IF @CapID IS NULL
       OR @KhoiID IS NULL
       OR @NienKhoa IS NULL
       OR NULLIF(LTRIM(RTRIM(@LopChonID)), '') IS NULL
       OR @MonHocLopID IS NULL
       OR @MonHocID IS NULL
       OR @TemplateBangDiemID IS NULL
    BEGIN
        RAISERROR('CapID, KhoiID, NienKhoa, LopChonID, MonHocLopID, MonHocID va TemplateBangDiemID la bat buoc.', 16, 1);
        RETURN;
    END;

    IF @HocKy IS NOT NULL AND @HocKy NOT IN (1, 2)
    BEGIN
        RAISERROR('HocKy phai la 1, 2 hoac NULL de lay ca hai hoc ky.', 16, 1);
        RETURN;
    END;

    -- LopChonID la lop/nhom giao vien dang chon; NienKhoa va MonHocLopID tranh gop nham LopID trung.
    ;WITH ScopedRows AS
    (
        SELECT
            header.SyncDiemLogID,
            header.SyncStatus,
            header.RequestedAt,
            header.CompletedAt,
            header.RequestedBy,
            header.RequestedByName,
            detail.HocSinhID,
            detail.MaCotDiem,
            detail.HocKy,
            detail.KetQua
        FROM dbo.tbl_LOG_LMS_SyncDiem AS header
        INNER JOIN dbo.tbl_LOG_LMS_SyncDiem_Detail AS detail
            ON detail.SyncDiemLogID = header.SyncDiemLogID
        WHERE header.CapID = @CapID
          AND header.KhoiID = @KhoiID
          AND header.NienKhoa = @NienKhoa
          AND header.LopChonID = @LopChonID
          AND header.MonHocLopID = @MonHocLopID
          AND header.MonHocID = @MonHocID
          AND header.TemplateBangDiemID = @TemplateBangDiemID
          -- Icon lịch sử được dùng cho mọi loại điểm đang công bố sang phụ huynh.
          AND header.LoaiDiem IN ('TX', 'DiemGK', 'DiemCK')
          AND (@HocKy IS NULL OR header.HocKy = @HocKy)
          AND detail.HocSinhID IS NOT NULL
          AND NULLIF(LTRIM(RTRIM(detail.MaCotDiem)), '') IS NOT NULL
    ),
    SendCounts AS
    (
        SELECT
            HocSinhID,
            MaCotDiem,
            HocKy,
            COUNT(DISTINCT CASE WHEN SyncStatus = 'Succeeded' THEN SyncDiemLogID END) AS SuccessfulSendCount
        FROM ScopedRows
        GROUP BY HocSinhID, MaCotDiem, HocKy
    ),
    RankedAttempts AS
    (
        SELECT *, ROW_NUMBER() OVER
        (
            PARTITION BY HocSinhID, MaCotDiem, HocKy
            ORDER BY RequestedAt DESC, SyncDiemLogID DESC
        ) AS RowNumber
        FROM ScopedRows
    ),
    RankedSuccessfulSends AS
    (
        SELECT *, ROW_NUMBER() OVER
        (
            PARTITION BY HocSinhID, MaCotDiem, HocKy
            ORDER BY RequestedAt DESC, SyncDiemLogID DESC
        ) AS RowNumber
        FROM ScopedRows
        WHERE SyncStatus = 'Succeeded'
    )
    SELECT
        counts.HocSinhID,
        counts.MaCotDiem,
        counts.HocKy,
        counts.SuccessfulSendCount,
        latestSuccess.KetQua AS LastSuccessfulScore,
        COALESCE(latestSuccess.CompletedAt, latestSuccess.RequestedAt) AS LastSuccessfulAt,
        latestSuccess.RequestedBy AS LastSuccessfulBy,
        latestSuccess.RequestedByName AS LastSuccessfulByName,
        latestAttempt.SyncStatus AS LastAttemptStatus,
        latestAttempt.KetQua AS LastAttemptScore,
        latestAttempt.RequestedAt AS LastAttemptAt,
        latestAttempt.RequestedBy AS LastAttemptBy,
        latestAttempt.RequestedByName AS LastAttemptByName
    FROM SendCounts AS counts
    LEFT JOIN RankedAttempts AS latestAttempt
        ON latestAttempt.HocSinhID = counts.HocSinhID
       AND latestAttempt.MaCotDiem = counts.MaCotDiem
       AND latestAttempt.HocKy = counts.HocKy
       AND latestAttempt.RowNumber = 1
    LEFT JOIN RankedSuccessfulSends AS latestSuccess
        ON latestSuccess.HocSinhID = counts.HocSinhID
       AND latestSuccess.MaCotDiem = counts.MaCotDiem
       AND latestSuccess.HocKy = counts.HocKy
       AND latestSuccess.RowNumber = 1
    ORDER BY counts.HocSinhID, counts.MaCotDiem, counts.HocKy;
END;


