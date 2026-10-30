CREATE PROCEDURE dbo.spAPI_TKB_Lich_Ins
    @NienKhoa VARCHAR(20),
    @LopHocID INT,
    @Lop NVARCHAR(200),
    @Thu INT,
    @BuoiID INT,
    @Tiet INT,
    @MonHocID INT,
    @MaMon VARCHAR(50),
    @TenMonHoc NVARCHAR(200),
    @GiaoVienID VARCHAR(50),
    @GhiChu NVARCHAR(MAX),
    @MaDonVi INT,
    @CapHoc INT,
    @TuanID INT,
    @HocKy INT,
    @ThoiKhoaBieu_CalenID VARCHAR(50),
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền chỉnh sửa thời khóa biểu.', 16, 1);
        RETURN;
    END;
    IF NULLIF(LTRIM(RTRIM(@Lop)), N'') IS NULL
       OR @Thu NOT BETWEEN 2 AND 7 OR @BuoiID NOT IN (1, 2) OR @Tiet NOT BETWEEN 1 AND 5
    BEGIN
        RAISERROR(N'Lớp, thứ, buổi hoặc tiết không hợp lệ.', 16, 1);
        RETURN;
    END;

    SET @MaMon = NULLIF(LTRIM(RTRIM(@MaMon)), '');
    SET @GiaoVienID = NULLIF(LTRIM(RTRIM(@GiaoVienID)), '');
    SET @CapHoc = ISNULL(@CapHoc, 0);
    SET @TuanID = NULLIF(@TuanID, 0);

    IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 1 AND UPPER(ISNULL(@MaMon, '')) <> 'KHAC'
    BEGIN
        RAISERROR(N'Tiết 1 buổi chiều phải là Hoạt động khác.', 16, 1);
        RETURN;
    END;
    IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 2
       AND (NULLIF(@MaMon, '') IS NULL OR UPPER(@MaMon) = 'KHAC')
    BEGIN
        RAISERROR(N'Tiết 2 buổi chiều phải là tiết học có mã môn.', 16, 1);
        RETURN;
    END;
    IF @MaMon IS NOT NULL AND UPPER(@MaMon) = 'KHAC'
    BEGIN
        SET @MonHocID = NULL;
        SET @MaMon = 'KHAC';
        SET @TenMonHoc = N'Hoạt động khác';
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Khóa ghi TKB trong lúc kiểm tra để hai yêu cầu đồng thời không cùng tạo lịch trùng.
        IF @CapHoc = 0
        BEGIN
            DECLARE @LockResult INT;
            EXEC @LockResult = sys.sp_getapplock
                @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
                @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
            IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để kiểm tra xung đột. Vui lòng thử lại.', 16, 1);
        END;

        IF EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
        )
            RAISERROR(N'Lớp đã có tiết ở đúng thứ, buổi và khung giờ này.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet >= 2
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = 1
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
                 AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(MaMon)), ''), '')) = 'KHAC'
           )
            RAISERROR(N'Buổi chiều phải bắt đầu bằng Hoạt động khác ở tiết 1.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet >= 3
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = 2
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
                 AND NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL
                 AND UPPER(LTRIM(RTRIM(MaMon))) <> 'KHAC'
           )
            RAISERROR(N'Sau tiết hoạt động đầu buổi chiều, tiết 2 phải có môn học trước khi xếp các tiết sau.', 16, 1);

        IF NULLIF(@GiaoVienID, '') IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
              AND (GiaoVienID = @GiaoVienID OR GiaoVienDayThayID = @GiaoVienID)
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
              AND NOT ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
        )
            RAISERROR(N'Giáo viên đã được xếp ở lớp khác cùng thứ, buổi và tiết này.', 16, 1);

        INSERT INTO dbo.tblTKB_Lich
            (NienKhoa, CapHoc, LopHocID, Lop, Thu, BuoiID, Tiet, MonHocID, MaMon, TenMonHoc,
             GiaoVienID, GhiChu, MaDonVi, NgayTao, NguoiTao, HocKy, TuanID, ThoiKhoaBieu_CalenID)
        VALUES
            (@NienKhoa, @CapHoc, @LopHocID, @Lop, @Thu, @BuoiID, @Tiet, @MonHocID, @MaMon, @TenMonHoc,
             @GiaoVienID, @GhiChu, @MaDonVi, GETDATE(), @sys_UserID, @HocKy, @TuanID,
             NULLIF(@ThoiKhoaBieu_CalenID, ''));

        DECLARE @TKBLichID INT = CONVERT(INT, SCOPE_IDENTITY());
        COMMIT TRANSACTION;
        SELECT @TKBLichID AS TKBLichID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH;
END
