

CREATE PROCEDURE [dbo].[spAPI_FP_HocLieu_Save]
    @HocLieuID INT,
    @TenHocLieu NVARCHAR(255),
    @BoSachID INT = NULL,
    @MonHocID INT = NULL,
    @KhoiID INT = NULL,
    @HocKy INT = NULL,
    @TinhTrang VARCHAR(50),
    @ThumbnailURL NVARCHAR(1000),
    @ThumbnailURLs NVARCHAR(MAX) = NULL,
    @Loai VARCHAR(50) = 'HOC_LIEU', -- Thêm mới để hỗ trợ lưu loại tài nguyên
    @sys_UserID VARCHAR(50)
AS
BEGIN
    IF ISNULL(@HocLieuID, 0) > 0
    BEGIN
        UPDATE dbo.tblHocLieu_FP 
        SET TenHocLieu = @TenHocLieu, 
            BoSachID = @BoSachID, 
            MonHocID = @MonHocID, 
            KhoiID = @KhoiID, 
            HocKy = @HocKy, 
            TinhTrang = @TinhTrang, 
            ThumbnailURL = @ThumbnailURL, 
            ThumbnailURLs = @ThumbnailURLs,
            Loai = @Loai,
            UpdateUser = @sys_UserID, 
            UpdateTime = GETDATE() 
        WHERE HocLieuID = @HocLieuID;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblHocLieu_FP (TenHocLieu, BoSachID, MonHocID, KhoiID, HocKy, TinhTrang, ThumbnailURL, ThumbnailURLs, Loai, CreateUser, CreateTime) 
        VALUES (@TenHocLieu, @BoSachID, @MonHocID, @KhoiID, @HocKy, @TinhTrang, @ThumbnailURL, @ThumbnailURLs, @Loai, @sys_UserID, GETDATE());
    END

    SELECT * FROM dbo.tblHocLieu_FP WHERE HocLieuID = ISNULL(@HocLieuID, SCOPE_IDENTITY());
END