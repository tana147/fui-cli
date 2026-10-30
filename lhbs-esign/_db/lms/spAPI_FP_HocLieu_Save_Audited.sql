
CREATE   PROCEDURE dbo.spAPI_FP_HocLieu_Save_Audited
    @HocLieuID INT,
    @TenHocLieu NVARCHAR(255),
    @BoSachID INT,
    @MonHocID INT,
    @KhoiID INT,
    @HocKy INT,
    @TinhTrang VARCHAR(50),
    @ThumbnailURL NVARCHAR(1000),
    @ThumbnailURLs NVARCHAR(MAX),
    @Loai VARCHAR(50),
    @OperationID UNIQUEIDENTIFIER,
    @OperationName NVARCHAR(150),
    @SourceModule VARCHAR(100),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = @OperationID;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = @OperationName;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = @SourceModule;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = @sys_UserID;

        EXEC dbo.spAPI_FP_HocLieu_Save
            @HocLieuID = @HocLieuID,
            @TenHocLieu = @TenHocLieu,
            @BoSachID = @BoSachID,
            @MonHocID = @MonHocID,
            @KhoiID = @KhoiID,
            @HocKy = @HocKy,
            @TinhTrang = @TinhTrang,
            @ThumbnailURL = @ThumbnailURL,
            @ThumbnailURLs = @ThumbnailURLs,
            @Loai = @Loai,
            @sys_UserID = @sys_UserID;

        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = NULL;
    END TRY
    BEGIN CATCH
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationID', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.OperationName', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.SourceModule', @value = NULL;
        EXEC sys.sp_set_session_context @key = N'HocLieu.ActorUserID', @value = NULL;
        THROW;
    END CATCH
END;
