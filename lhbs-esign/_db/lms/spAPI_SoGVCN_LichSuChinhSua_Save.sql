CREATE PROCEDURE dbo.spAPI_SoGVCN_LichSuChinhSua_Save
    @SoGVCNID INT,
    @NienKhoa INT,
    @KhoiID INT,
    @LopID VARCHAR(20),
    @JsonLogs NVARCHAR(MAX),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @HoTenUser NVARCHAR(100) = NULL;
    DECLARE @CreateUser VARCHAR(50) = @sys_UserID;

    IF @sys_UserID IS NOT NULL AND @sys_UserID <> ''
    BEGIN
        SELECT TOP 1 @HoTenUser = RTRIM(ISNULL(HoGV, '')) + ' ' + RTRIM(ISNULL(TenGV, ''))
        FROM dbo.tblGiaoVien
        WHERE RTRIM(GiaoVienID) = RTRIM(@sys_UserID);
    END;

    -- Nếu không có hoặc chưa có tên GV từ sys_UserID, lấy theo GVCN của lớp
    IF @HoTenUser IS NULL OR @HoTenUser = ''
    BEGIN
        SELECT TOP 1 
            @HoTenUser = RTRIM(ISNULL(gv.HoGV, '')) + ' ' + RTRIM(ISNULL(gv.TenGV, '')),
            @CreateUser = ISNULL(@CreateUser, RTRIM(l.GVCN))
        FROM dbo.tblLop l
        LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
        WHERE l.LopID = @LopID
      AND l.NienKhoa = @NienKhoa;
    END;

    IF @HoTenUser IS NULL OR @HoTenUser = ''
        SET @HoTenUser = ISNULL(@CreateUser, N'Giáo viên');

    INSERT INTO dbo.tblSoGVCN_LichSuChinhSua
    (
        SoGVCNID, NienKhoa, KhoiID, LopID,
        MaTab, TenTab, MaMuc, TenMuc, NhomMuc,
        TenDong, NoiDungChinhSua, GiaTriCu, GiaTriMoi,
        CreateUser, HoTenUser, CreateTime, Enable
    )
    SELECT
        @SoGVCNID,
        @NienKhoa,
        @KhoiID,
        @LopID,
        j.MaTab,
        j.TenTab,
        j.MaMuc,
        j.TenMuc,
        j.NhomMuc,
        j.TenDong,
        j.NoiDungChinhSua,
        j.GiaTriCu,
        j.GiaTriMoi,
        ISNULL(ISNULL(NULLIF(j.CreateUser, ''), @CreateUser), 'NV0000001'),
        ISNULL(ISNULL(NULLIF(j.HoTenUser, ''), @HoTenUser), N'Giáo viên'),
        ISNULL(TRY_CONVERT(DATETIME, j.CreateTime), GETDATE()),
        1
    FROM OPENJSON(@JsonLogs)
    WITH (
        MaTab VARCHAR(50) '$.MaTab',
        TenTab NVARCHAR(150) '$.TenTab',
        MaMuc VARCHAR(100) '$.MaMuc',
        TenMuc NVARCHAR(255) '$.TenMuc',
        NhomMuc NVARCHAR(150) '$.NhomMuc',
        TenDong NVARCHAR(200) '$.TenDong',
        NoiDungChinhSua NVARCHAR(MAX) '$.NoiDungChinhSua',
        GiaTriCu NVARCHAR(MAX) '$.GiaTriCu',
        GiaTriMoi NVARCHAR(MAX) '$.GiaTriMoi',
        CreateUser VARCHAR(50) '$.CreateUser',
        HoTenUser NVARCHAR(100) '$.HoTenUser',
        CreateTime VARCHAR(30) '$.CreateTime'
    ) AS j;

    SELECT 1 AS Success, @@ROWCOUNT AS RowsInserted;
END;