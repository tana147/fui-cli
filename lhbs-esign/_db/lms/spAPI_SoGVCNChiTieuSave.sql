CREATE PROCEDURE dbo.spAPI_SoGVCNChiTieuSave
    @SoGVCNID varchar(10),
    @JsonRows nvarchar(max),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- FUI gửi mã người dùng dạng chuỗi (ví dụ NA0000022). Trigger audit đọc
    -- mã này từ SESSION_CONTEXT; các cột CreateUser/UpdateUser legacy vẫn là INT.
    DECLARE @AuditUser varchar(20) = COALESCE(NULLIF(LTRIM(RTRIM(@sys_UserID)), ''), 'unknown/unavailable');
    EXEC sys.sp_set_session_context
        @key = N'SoGVCN_UserID',
        @value = @AuditUser;

    DECLARE @UserID int = ISNULL(TRY_CONVERT(int, @sys_UserID), 0);
    DECLARE @ID int = ISNULL(TRY_CONVERT(int, @SoGVCNID), 0);

    DECLARE @Rows TABLE
    (
        LoaiChiTieu varchar(30) NOT NULL,
        MatGiaoDuc nvarchar(200) NULL,
        YeuCau nvarchar(max) NULL,
        Tot int NULL,
        Kha int NULL,
        Dat int NULL,
        ChuaDat int NULL,
        BienPhap nvarchar(max) NULL,
        HSXS int NULL,
        HSG int NULL,
        NoiDung nvarchar(max) NULL,
        GhiChu nvarchar(max) NULL,
        RowIndex int NOT NULL
    );

    INSERT INTO @Rows
    (
        LoaiChiTieu, MatGiaoDuc, YeuCau, Tot, Kha, Dat, ChuaDat, BienPhap,
        HSXS, HSG, NoiDung, GhiChu, RowIndex
    )
    SELECT
        LoaiChiTieu, MatGiaoDuc, YeuCau, Tot, Kha, Dat, ChuaDat, BienPhap,
        HSXS, HSG, NoiDung, GhiChu, ISNULL(RowIndex, 0)
    FROM OPENJSON(ISNULL(@JsonRows, N'[]'))
    WITH
    (
        LoaiChiTieu varchar(30) '$.LoaiChiTieu',
        MatGiaoDuc nvarchar(200) '$.MatGiaoDuc',
        YeuCau nvarchar(max) '$.YeuCau',
        Tot int '$.Tot',
        Kha int '$.Kha',
        Dat int '$.Dat',
        ChuaDat int '$.ChuaDat',
        BienPhap nvarchar(max) '$.BienPhap',
        HSXS int '$.HSXS',
        HSG int '$.HSG',
        NoiDung nvarchar(max) '$.NoiDung',
        GhiChu nvarchar(max) '$.GhiChu',
        RowIndex int '$.RowIndex'
    )
    WHERE NULLIF(LTRIM(RTRIM(ISNULL(LoaiChiTieu, ''))), '') IS NOT NULL
      AND (
          NULLIF(LTRIM(RTRIM(ISNULL(MatGiaoDuc, ''))), '') IS NOT NULL
       OR NULLIF(LTRIM(RTRIM(ISNULL(NoiDung, ''))), '') IS NOT NULL
       OR NULLIF(LTRIM(RTRIM(CONCAT(YeuCau, Tot, Kha, Dat, ChuaDat, BienPhap, HSXS, HSG, GhiChu))), N'') IS NOT NULL
      );

    UPDATE target
    SET Enable = 0,
        UpdateUser = @UserID,
        UpdateTime = GETDATE()
    FROM dbo.tblSoGVCNChiTieu target
    WHERE target.SoGVCNID = @ID
      AND target.Enable = 1
      AND target.LoaiChiTieu IN ('GIAO_DUC', 'DANH_HIEU', 'PHONG_TRAO');

    INSERT INTO dbo.tblSoGVCNChiTieu
    (
        SoGVCNID, LoaiChiTieu, MatGiaoDuc, YeuCau, Tot, Kha, Dat, ChuaDat,
        BienPhap, HSXS, HSG, NoiDung, GhiChu, RowIndex, CreateUser, UpdateUser
    )
    SELECT
        @ID, LoaiChiTieu, MatGiaoDuc, YeuCau, Tot, Kha, Dat, ChuaDat,
        BienPhap, HSXS, HSG, NoiDung, GhiChu, RowIndex, @UserID, @UserID
    FROM @Rows;

    UPDATE dbo.tblSoGVCN
    SET TrangThai = CASE WHEN TrangThai = 'NEW' THEN 'DRAFT' ELSE TrangThai END,
        UpdateUser = @UserID,
        UpdateTime = GETDATE()
    WHERE SoGVCNID = @ID
      AND Enable = 1;

    SELECT mess = N'Đã lưu chỉ tiêu', SoGVCNID = @ID;
END
