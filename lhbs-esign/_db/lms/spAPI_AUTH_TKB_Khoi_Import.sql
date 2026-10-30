CREATE PROCEDURE dbo.spAPI_AUTH_TKB_Khoi_Import
    @SYS_USERID VARCHAR(50),
    @NamHoc VARCHAR(20),
    @Rows NVARCHAR(MAX),
    @DonViID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SELECT KhoiID, NamHoc, DonViID, TenKhoi
    INTO #TempKhoi
    FROM OPENJSON(@Rows)
    WITH (
        KhoiID INT '$.KhoiID',
        NamHoc VARCHAR(20) '$.NamHoc',
        DonViID INT '$.DonViID',
        TenKhoi NVARCHAR(200) '$.TenKhoi'
    )
    WHERE KhoiID IS NOT NULL;

    DECLARE @Warning TABLE (
        KhoiID INT,
        ExistingNamHoc VARCHAR(20),
        ExistingDonViID INT,
        ExistingTenKhoi NVARCHAR(200),
        IncomingNamHoc VARCHAR(20),
        IncomingDonViID INT,
        IncomingTenKhoi NVARCHAR(200)
    );

    INSERT INTO @Warning
    SELECT t.KhoiID, t.NamHoc, t.DonViID, t.TenKhoi,
           s.NamHoc, s.DonViID, s.TenKhoi
    FROM dbo.tblTKB_Khoi t
    INNER JOIN #TempKhoi s ON s.KhoiID = t.KhoiID
    WHERE ISNULL(t.NamHoc, '') <> ISNULL(s.NamHoc, '')
       OR ISNULL(t.DonViID, 0) <> ISNULL(s.DonViID, 0)
       OR ISNULL(t.TenKhoi, '') <> ISNULL(s.TenKhoi, '');

    UPDATE t
    SET t.TenKhoi = s.TenKhoi,
        t.NgayDongBo = GETDATE(),
        t.Nguon = 'Calen'
    FROM dbo.tblTKB_Khoi t
    INNER JOIN #TempKhoi s
        ON t.KhoiID = s.KhoiID
       AND ISNULL(t.NamHoc, '') = ISNULL(s.NamHoc, '')
       AND ISNULL(t.DonViID, 0) = ISNULL(s.DonViID, 0)
    WHERE ISNULL(t.TenKhoi, '') <> ISNULL(s.TenKhoi, '');

    INSERT INTO dbo.tblTKB_Khoi (KhoiID, NamHoc, DonViID, TenKhoi, NgayDongBo, Nguon)
    SELECT s.KhoiID, s.NamHoc, s.DonViID, s.TenKhoi, GETDATE(), 'Calen'
    FROM #TempKhoi s
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.tblTKB_Khoi t WHERE t.KhoiID = s.KhoiID
    );

    SELECT 1 AS Result,
        (SELECT COUNT(*) FROM @Warning) AS WarningCount,
        CASE WHEN EXISTS (SELECT 1 FROM @Warning)
             THEN N'Có khối trùng KhoiID nhưng khác thông tin; đã bỏ qua, không thêm dòng.'
             ELSE N'Đồng bộ khối thành công.'
        END AS Message;

    SELECT KhoiID, ExistingNamHoc, ExistingDonViID, ExistingTenKhoi,
           IncomingNamHoc, IncomingDonViID, IncomingTenKhoi
    FROM @Warning
    ORDER BY KhoiID;
END;