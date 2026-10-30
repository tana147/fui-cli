CREATE   PROCEDURE [dbo].[spAPI_FP_TaiNguyen_Save]
    @HocLieuID INT = 0,
    @TenHocLieu NVARCHAR(255),
    @MonHocID INT = NULL,
    @KhoiID INT = NULL,
    @TaiNguyenLoaiID INT = NULL,
    @TaiNguyenMucID INT = NULL,
    @HocKy INT = NULL,
    @TinhTrang VARCHAR(50) = 'Private',
    @ThumbnailURL NVARCHAR(1000) = NULL,
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
DECLARE @BoSachID INT;
    SET @MonHocID = ISNULL(@MonHocID, 0);
    SET @KhoiID = ISNULL(@KhoiID, 0);

    IF @TaiNguyenLoaiID IS NULL
        SELECT @TaiNguyenLoaiID = TaiNguyenLoaiID
        FROM dbo.tblFP_TaiNguyenLoai
        WHERE Code = 'TAI_LIEU_THAM_KHAO';

    IF NOT EXISTS (
        SELECT 1 FROM dbo.tblFP_TaiNguyenLoai
        WHERE TaiNguyenLoaiID = @TaiNguyenLoaiID AND IsActive = 1
    )
        THROW 50101, N'Loại tài nguyên không hợp lệ.', 1;

    IF @TaiNguyenMucID IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM dbo.tblFP_TaiNguyenMuc
           WHERE TaiNguyenMucID = @TaiNguyenMucID
             AND TaiNguyenLoaiID = @TaiNguyenLoaiID
             AND IsActive = 1
       )
        THROW 50102, N'Mức tài nguyên không hợp lệ.', 1;

    IF ISNULL(@HocLieuID, 0) > 0
    BEGIN
        UPDATE dbo.tblHocLieu_FP
        SET TenHocLieu = @TenHocLieu,
            MonHocID = @MonHocID,
            KhoiID = @KhoiID,
            TaiNguyenLoaiID = @TaiNguyenLoaiID,
            TaiNguyenMucID = @TaiNguyenMucID,
            HocKy = @HocKy,
            TinhTrang = ISNULL(NULLIF(@TinhTrang, ''), 'Private'),
            ThumbnailURL = @ThumbnailURL,
            UpdateUser = @sys_UserID,
            UpdateTime = GETDATE()
        WHERE HocLieuID = @HocLieuID
          AND Loai = 'TAI_NGUYEN'
          AND (@sys_SystemRight IN (3, 9) OR CreateUser = @sys_UserID)
          AND Is_Xoa = 0;

        IF @@ROWCOUNT = 0
            THROW 50103, N'Không tìm thấy bộ tài nguyên hoặc bạn không có quyền cập nhật.', 1;
    END
    ELSE
    BEGIN
        SELECT TOP (1) @BoSachID = BoSachID
        FROM dbo.tblBoSach_FP
        WHERE Is_Xoa = 0
        ORDER BY BoSachID;

        IF @BoSachID IS NULL
            THROW 50104, N'Không tìm thấy bộ sách đang hoạt động để tạo bộ tài nguyên.', 1;

        INSERT INTO dbo.tblHocLieu_FP
            (TenHocLieu, BoSachID, MonHocID, KhoiID, TaiNguyenLoaiID, TaiNguyenMucID,
             HocKy, ThumbnailURL, TinhTrang, Loai, Is_Xoa, CreateUser, CreateTime)
        VALUES
            (@TenHocLieu, @BoSachID, @MonHocID, @KhoiID, @TaiNguyenLoaiID, @TaiNguyenMucID,
             @HocKy, @ThumbnailURL, ISNULL(NULLIF(@TinhTrang, ''), 'Private'),
             'TAI_NGUYEN', 0, @sys_UserID, GETDATE());

        SET @HocLieuID = SCOPE_IDENTITY();
    END;

    SELECT * FROM dbo.tblHocLieu_FP WHERE HocLieuID = @HocLieuID;
END;
IF USER_NAME() <> N'lmslhbs' AND USER_NAME() <> N'dbo'
    GRANT EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Save] TO [lmslhbs];
REVOKE EXECUTE ON [dbo].[spAPI_FP_TaiNguyen_Save] FROM [public];
