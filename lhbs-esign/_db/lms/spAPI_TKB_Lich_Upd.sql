CREATE PROCEDURE dbo.spAPI_TKB_Lich_Upd
    @TKBLichID INT,
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
    @HocKy INT,
    @TuanID INT,
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

    DECLARE @OldNienKhoa VARCHAR(20), @OldMaDonVi INT, @OldLopHocID INT, @OldLop NVARCHAR(200),
            @OldThu INT, @OldBuoiID INT, @OldTiet INT, @OldCapHoc INT, @OldTuanID INT,
            @OldMaMon VARCHAR(50), @OldGiaoVienID VARCHAR(50), @OldGiaoVienDayThayID VARCHAR(10),
            @OldHocKy INT, @OldMonHocID INT, @OldTenMonHoc NVARCHAR(200), @OldGhiChu NVARCHAR(MAX),
            @OldCalenID VARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @LockResult INT;
        EXEC @LockResult = sys.sp_getapplock
            @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để kiểm tra xung đột. Vui lòng thử lại.', 16, 1);

        SELECT @OldNienKhoa = NienKhoa, @OldMaDonVi = MaDonVi, @OldLopHocID = LopHocID,
               @OldLop = Lop, @OldThu = Thu, @OldBuoiID = BuoiID, @OldTiet = Tiet,
               @OldCapHoc = CapHoc, @OldTuanID = TuanID, @OldMaMon = MaMon,
               @OldGiaoVienID = GiaoVienID, @OldGiaoVienDayThayID = GiaoVienDayThayID,
               @OldHocKy = HocKy, @OldMonHocID = MonHocID, @OldTenMonHoc = TenMonHoc,
               @OldGhiChu = GhiChu, @OldCalenID = ThoiKhoaBieu_CalenID
        FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
        WHERE TKBLichID = @TKBLichID;

        IF @OldNienKhoa IS NULL RAISERROR(N'Không tìm thấy tiết học cần cập nhật.', 16, 1);

        SET @NienKhoa = ISNULL(@NienKhoa, @OldNienKhoa);
        SET @MaDonVi = ISNULL(@MaDonVi, @OldMaDonVi);
        SET @LopHocID = ISNULL(@LopHocID, @OldLopHocID);
        SET @Lop = ISNULL(@Lop, @OldLop);
        SET @Thu = ISNULL(@Thu, @OldThu);
        SET @BuoiID = ISNULL(@BuoiID, @OldBuoiID);
        SET @Tiet = ISNULL(@Tiet, @OldTiet);
        SET @CapHoc = ISNULL(@CapHoc, @OldCapHoc);
        SET @HocKy = ISNULL(@HocKy, @OldHocKy);
        SET @TuanID = CASE WHEN @TuanID IS NULL THEN @OldTuanID ELSE NULLIF(@TuanID, 0) END;
        SET @MaMon = CASE WHEN @MaMon IS NULL THEN @OldMaMon ELSE NULLIF(LTRIM(RTRIM(@MaMon)), '') END;
        SET @GiaoVienID = CASE WHEN @GiaoVienID IS NULL THEN @OldGiaoVienID ELSE NULLIF(LTRIM(RTRIM(@GiaoVienID)), '') END;
        SET @MonHocID = CASE WHEN UPPER(ISNULL(@MaMon, '')) = 'KHAC' THEN NULL ELSE ISNULL(@MonHocID, @OldMonHocID) END;
        SET @TenMonHoc = CASE WHEN UPPER(ISNULL(@MaMon, '')) = 'KHAC' THEN N'Hoạt động khác' ELSE ISNULL(@TenMonHoc, @OldTenMonHoc) END;
        SET @GhiChu = ISNULL(@GhiChu, @OldGhiChu);
        SET @ThoiKhoaBieu_CalenID = ISNULL(@ThoiKhoaBieu_CalenID, @OldCalenID);

        IF NULLIF(LTRIM(RTRIM(@Lop)), N'') IS NULL
           OR @Thu NOT BETWEEN 2 AND 7 OR @BuoiID NOT IN (1, 2) OR @Tiet NOT BETWEEN 1 AND 5
            RAISERROR(N'Lớp, thứ, buổi hoặc tiết không hợp lệ.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 1 AND UPPER(ISNULL(@MaMon, '')) <> 'KHAC'
            RAISERROR(N'Tiết 1 buổi chiều phải là Hoạt động khác.', 16, 1);
        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 2
           AND (NULLIF(@MaMon, '') IS NULL OR UPPER(@MaMon) = 'KHAC')
            RAISERROR(N'Tiết 2 buổi chiều phải là tiết học có mã môn.', 16, 1);

        -- Khi đổi/xóa vị trí đầu buổi, không để lại các tiết chiều phía sau thiếu thứ tự.
        IF @OldCapHoc = 0 AND @OldBuoiID = 2 AND @OldTiet = 1
           AND NOT (@CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 1 AND UPPER(ISNULL(@MaMon, '')) = 'KHAC')
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @OldNienKhoa AND MaDonVi = @OldMaDonVi
                 AND ((LopHocID = @OldLopHocID) OR (LopHocID IS NULL AND Lop = @OldLop))
                 AND Thu = @OldThu AND BuoiID = 2 AND Tiet >= 2 AND TKBLichID <> @TKBLichID
                 AND (TuanID IS NULL OR TuanID = 0 OR @OldTuanID IS NULL OR TuanID = @OldTuanID)
           )
            RAISERROR(N'Không thể đổi tiết hoạt động đầu buổi chiều khi lớp vẫn còn tiết phía sau.', 16, 1);

        IF @OldCapHoc = 0 AND @OldBuoiID = 2 AND @OldTiet = 2
           AND NOT (@CapHoc = 0 AND @BuoiID = 2 AND @Tiet = 2 AND NULLIF(@MaMon, '') IS NOT NULL AND UPPER(@MaMon) <> 'KHAC')
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @OldNienKhoa AND MaDonVi = @OldMaDonVi
                 AND ((LopHocID = @OldLopHocID) OR (LopHocID IS NULL AND Lop = @OldLop))
                 AND Thu = @OldThu AND BuoiID = 2 AND Tiet > 2 AND TKBLichID <> @TKBLichID
                 AND (TuanID IS NULL OR TuanID = 0 OR @OldTuanID IS NULL OR TuanID = @OldTuanID)
           )
            RAISERROR(N'Không thể đổi tiết học thứ 2 buổi chiều khi lớp vẫn còn tiết sau.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet >= 2
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = 1 AND TKBLichID <> @TKBLichID
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
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = 2 AND TKBLichID <> @TKBLichID
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
                 AND NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL
                 AND UPPER(LTRIM(RTRIM(MaMon))) <> 'KHAC'
           )
            RAISERROR(N'Sau tiết hoạt động đầu buổi chiều, tiết 2 phải có môn học trước khi xếp các tiết sau.', 16, 1);

        IF NULLIF(@GiaoVienID, '') IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
              AND TKBLichID <> @TKBLichID
              AND (GiaoVienID = @GiaoVienID OR GiaoVienDayThayID = @GiaoVienID)
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
              AND NOT ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
        )
            RAISERROR(N'Giáo viên đã được xếp ở lớp khác cùng thứ, buổi và tiết này.', 16, 1);

        IF EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet AND TKBLichID <> @TKBLichID
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
        )
            RAISERROR(N'Lớp đã có tiết ở đúng thứ, buổi và khung giờ này.', 16, 1);

        UPDATE dbo.tblTKB_Lich
        SET NienKhoa = @NienKhoa, CapHoc = @CapHoc, LopHocID = @LopHocID, Lop = @Lop,
            Thu = @Thu, BuoiID = @BuoiID, Tiet = @Tiet, MonHocID = @MonHocID,
            MaMon = @MaMon, TenMonHoc = @TenMonHoc, GiaoVienID = @GiaoVienID,
            GhiChu = @GhiChu, MaDonVi = @MaDonVi, HocKy = @HocKy, TuanID = @TuanID,
            ThoiKhoaBieu_CalenID = NULLIF(@ThoiKhoaBieu_CalenID, '')
        WHERE TKBLichID = @TKBLichID;

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
