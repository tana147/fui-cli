CREATE PROCEDURE dbo.spAPI_TKB_Lich_DayThay_Upd
    @TKBLichID INT,
    @GiaoVienDayThayID VARCHAR(10),
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật giáo viên dạy thay.', 16, 1);
        RETURN;
    END;

    SET @GiaoVienDayThayID = NULLIF(LTRIM(RTRIM(@GiaoVienDayThayID)), '');
    IF @GiaoVienDayThayID = '0' SET @GiaoVienDayThayID = NULL;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockResult INT;
        EXEC @LockResult = sys.sp_getapplock
            @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để kiểm tra xung đột. Vui lòng thử lại.', 16, 1);

        DECLARE @NienKhoa VARCHAR(20), @LopHocID INT, @Lop NVARCHAR(200), @Thu INT,
                @BuoiID INT, @Tiet INT, @TuanID INT;
        SELECT @NienKhoa = NienKhoa, @LopHocID = LopHocID, @Lop = Lop, @Thu = Thu,
               @BuoiID = BuoiID, @Tiet = Tiet, @TuanID = TuanID
        FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
        WHERE TKBLichID = @TKBLichID;
        IF @NienKhoa IS NULL RAISERROR(N'Không tìm thấy tiết học cần cập nhật.', 16, 1);

        IF @GiaoVienDayThayID IS NOT NULL AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
              AND TKBLichID <> @TKBLichID
              AND (GiaoVienID = @GiaoVienDayThayID OR GiaoVienDayThayID = @GiaoVienDayThayID)
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
              AND NOT ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
        )
            RAISERROR(N'Giáo viên dạy thay đã được xếp ở lớp khác cùng thứ, buổi và tiết này.', 16, 1);

        UPDATE dbo.tblTKB_Lich
        SET GiaoVienDayThayID = @GiaoVienDayThayID
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
