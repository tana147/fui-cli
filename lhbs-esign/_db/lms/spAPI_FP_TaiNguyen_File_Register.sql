
/* Giữ nguyên luồng upload bài học/bài tập: kho tự sinh thuộc tài liệu tham khảo. */
CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_File_Register]
    @KhoiID INT = NULL,
    @MonHocID INT = NULL,
    @BoSachID INT = NULL,
    @TenNoiDung NVARCHAR(500),
    @LoaiNoiDung VARCHAR(50),
    @DataJson NVARCHAR(MAX),
    @NguonTaiNguyenCode VARCHAR(50) = 'HOC_LIEU',
    @NguonResourceType VARCHAR(50) = NULL,
    @NguonResourceID INT = NULL,
    @sys_UserID VARCHAR(50),
    @sys_SystemRight INT = 0,
    @sys_FunctionRight VARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    
    IF dbo.fn_CheckUserPermission(
           @sys_SystemRight,
           @sys_FunctionRight,
           '[1][2][3][5][9]',
           NULL
       ) = 0
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thực hiện chức năng quản lý tài nguyên này.', 16, 1);
        RETURN;
    END;
SET XACT_ABORT ON;

    IF ISJSON(@DataJson) = 0
        THROW 50104, N'Metadata file không phải JSON hợp lệ.', 1;

    DECLARE @HocLieuID INT, @TenKho NVARCHAR(255) = N'Tài nguyên đã tải lên';
    DECLARE @TaiNguyenLoaiID INT;
    SELECT @TaiNguyenLoaiID = TaiNguyenLoaiID FROM dbo.tblFP_TaiNguyenLoai WHERE Code = 'TAI_LIEU_THAM_KHAO';

    /* BoSachID là bắt buộc ở tblHocLieu_FP; 0/null được quy về bộ sách đang hoạt động. */
    SET @BoSachID = NULLIF(@BoSachID, 0);
    IF @BoSachID IS NULL
        SELECT TOP (1) @BoSachID = BoSachID
        FROM dbo.tblBoSach_FP
        WHERE Is_Xoa = 0
        ORDER BY BoSachID;

    IF @BoSachID IS NULL
        THROW 50105, N'Không tìm thấy bộ sách đang hoạt động để tạo kho tài nguyên.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblBoSach_FP WHERE BoSachID = @BoSachID AND Is_Xoa = 0)
        THROW 50106, N'Bộ sách không hợp lệ hoặc đã bị xóa.', 1;

    BEGIN TRANSACTION;
    SELECT TOP (1) @HocLieuID = HocLieuID
    FROM dbo.tblHocLieu_FP WITH (UPDLOCK, HOLDLOCK)
    WHERE Loai = 'TAI_NGUYEN' AND CreateUser = @sys_UserID AND Is_Xoa = 0
      AND ISNULL(KhoiID, -1) = ISNULL(@KhoiID, -1)
      AND ISNULL(MonHocID, -1) = ISNULL(@MonHocID, -1)
      AND TenHocLieu = @TenKho;

    IF @HocLieuID IS NULL
    BEGIN
        INSERT INTO dbo.tblHocLieu_FP
            (TenHocLieu, BoSachID, MonHocID, KhoiID, TaiNguyenLoaiID, TinhTrang, Loai, Is_Xoa, CreateUser, CreateTime)
        VALUES (@TenKho, @BoSachID, @MonHocID, @KhoiID, @TaiNguyenLoaiID, 'Private', 'TAI_NGUYEN', 0, @sys_UserID, GETDATE());
        SET @HocLieuID = SCOPE_IDENTITY();
    END
    ELSE IF EXISTS (SELECT 1 FROM dbo.tblHocLieu_FP WHERE HocLieuID = @HocLieuID AND TaiNguyenLoaiID IS NULL)
    BEGIN
        UPDATE dbo.tblHocLieu_FP SET TaiNguyenLoaiID = @TaiNguyenLoaiID WHERE HocLieuID = @HocLieuID;
    END;

    DECLARE @FileID VARCHAR(100) = JSON_VALUE(@DataJson, '$.fileId');
    DECLARE @SourceNoiDungID INT = TRY_CAST(JSON_VALUE(@DataJson, '$.sourceNoiDungID') AS INT);
    DECLARE @NoiDungID INT;
    SELECT TOP (1) @NoiDungID = NoiDungID FROM dbo.tblNoiDungHocLieu_FP
    WHERE HocLieuID = @HocLieuID AND Is_Xoa = 0 AND JSON_VALUE(DataJson, '$.fileId') = @FileID
      AND (@SourceNoiDungID IS NULL OR TRY_CAST(JSON_VALUE(DataJson, '$.sourceNoiDungID') AS INT) = @SourceNoiDungID)
    ORDER BY NoiDungID;

    IF @NoiDungID IS NOT NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT @HocLieuID AS HocLieuID, @NoiDungID AS NoiDungID;
        RETURN;
    END;

    INSERT INTO dbo.tblNoiDungHocLieu_FP
        (HocLieuID, ParentID, TenNoiDung, LoaiNoiDung, ThuTu, DataJson,
         NguonTaiNguyenCode, NguonResourceType, NguonResourceID,
         Is_Xoa, CreateUser, CreateTime)
    SELECT @HocLieuID, NULL, @TenNoiDung, @LoaiNoiDung, ISNULL(MAX(ThuTu), -1) + 1,
           @DataJson, @NguonTaiNguyenCode, @NguonResourceType, @NguonResourceID,
           0, @sys_UserID, GETDATE()
    FROM dbo.tblNoiDungHocLieu_FP
    WHERE HocLieuID = @HocLieuID AND ParentID IS NULL AND Is_Xoa = 0;

    SET @NoiDungID = SCOPE_IDENTITY();
    COMMIT TRANSACTION;
    SELECT @HocLieuID AS HocLieuID, @NoiDungID AS NoiDungID;
END;

GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_File_Register] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_File_Register] FROM [public];
