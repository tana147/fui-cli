CREATE PROCEDURE dbo.spAPI_TKB_Lich_Del
    @TKBLichID INT,
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

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockResult INT;
        EXEC @LockResult = sys.sp_getapplock
            @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để kiểm tra. Vui lòng thử lại.', 16, 1);

        DECLARE @NienKhoa VARCHAR(20), @MaDonVi INT, @LopHocID INT, @Lop NVARCHAR(200),
                @Thu INT, @BuoiID INT, @Tiet INT, @CapHoc INT, @TuanID INT;
        SELECT @NienKhoa = NienKhoa, @MaDonVi = MaDonVi, @LopHocID = LopHocID, @Lop = Lop,
               @Thu = Thu, @BuoiID = BuoiID, @Tiet = Tiet, @CapHoc = CapHoc, @TuanID = TuanID
        FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
        WHERE TKBLichID = @TKBLichID;
        IF @NienKhoa IS NULL RAISERROR(N'Không tìm thấy tiết học cần xóa.', 16, 1);

        IF ISNULL(@CapHoc, 0) = 0 AND @BuoiID = 2 AND @Tiet = 1 AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = 2 AND Tiet >= 2
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
        )
            RAISERROR(N'Không thể xóa Hoạt động khác khi lớp vẫn còn tiết chiều phía sau.', 16, 1);

        IF ISNULL(@CapHoc, 0) = 0 AND @BuoiID = 2 AND @Tiet = 2 AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = 2 AND Tiet > 2
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
        )
            RAISERROR(N'Không thể xóa tiết học thứ 2 khi lớp vẫn còn tiết chiều phía sau.', 16, 1);

        DELETE FROM dbo.tblTKB_Lich WHERE TKBLichID = @TKBLichID;
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
