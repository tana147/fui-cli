CREATE PROCEDURE dbo.spAPI_AUTH_TKB_MN_Lich_Ins
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
        RAISERROR(N'[Unauthorized]Bạn không có quyền chỉnh sửa thời khóa biểu.', 16, 1);
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

        DECLARE @NgayBatDauTuan DATE = NULL;
        IF @TuanID IS NOT NULL
            SELECT @NgayBatDauTuan = NgayBatDau
            FROM dbo.tblTuanHocTap WITH (NOLOCK)
            WHERE TuanHocID = @TuanID;

        -- Hai tiết đầu buổi chiều có thể đổi thứ tự: một tiết học và một tiết KHAC.
        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet IN (1, 2) AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = 2 AND Tiet = CASE WHEN @Tiet = 1 THEN 2 ELSE 1 END
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
              AND (
                    (UPPER(ISNULL(@MaMon, '')) = 'KHAC' AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(MaMon)), ''), '')) = 'KHAC')
                 OR (NULLIF(@MaMon, '') IS NOT NULL AND UPPER(@MaMon) <> 'KHAC'
                     AND NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(MaMon))) <> 'KHAC')
              )
        )
            RAISERROR(N'Hai tiết đầu buổi chiều cần có một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet IN (1, 2)
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet >= 3
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
           )
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = CASE WHEN @Tiet = 1 THEN 2 ELSE 1 END
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
                 AND (
                       (UPPER(ISNULL(@MaMon, '')) = 'KHAC'
                        AND NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(MaMon))) <> 'KHAC')
                    OR (NULLIF(@MaMon, '') IS NOT NULL AND UPPER(@MaMon) <> 'KHAC'
                        AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(MaMon)), ''), '')) = 'KHAC')
                 )
           )
            RAISERROR(N'Không thể xếp tiết chiều tiếp theo khi hai tiết đầu chưa tạo thành một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet >= 3 AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.tblTKB_Lich AS P1 WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.tblTKB_Lich AS P2 WITH (UPDLOCK, HOLDLOCK)
                ON P2.NienKhoa = P1.NienKhoa AND P2.MaDonVi = P1.MaDonVi
               AND ((P2.LopHocID = P1.LopHocID) OR (P2.LopHocID IS NULL AND P1.LopHocID IS NULL AND P2.Lop = P1.Lop))
               AND P2.Thu = P1.Thu AND P2.BuoiID = 2 AND P2.Tiet = 2
               AND (P2.TuanID IS NULL OR P2.TuanID = 0 OR @TuanID IS NULL OR P2.TuanID = @TuanID)
            WHERE P1.NienKhoa = @NienKhoa AND P1.MaDonVi = @MaDonVi
              AND ((P1.LopHocID = @LopHocID) OR (P1.LopHocID IS NULL AND P1.Lop = @Lop))
              AND P1.Thu = @Thu AND P1.BuoiID = 2 AND P1.Tiet = 1
              AND (P1.TuanID IS NULL OR P1.TuanID = 0 OR @TuanID IS NULL OR P1.TuanID = @TuanID)
              AND (
                    (UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P1.MaMon)), ''), '')) = 'KHAC'
                     AND NULLIF(LTRIM(RTRIM(P2.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P2.MaMon))) <> 'KHAC')
                 OR (NULLIF(LTRIM(RTRIM(P1.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P1.MaMon))) <> 'KHAC'
                     AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P2.MaMon)), ''), '')) = 'KHAC')
              )
        )
            RAISERROR(N'Trước tiết chiều thứ 3 trở đi phải có đủ hai tiết đầu: một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);

        IF @CapHoc = 0 AND @NgayBatDauTuan IS NULL AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
            WHERE Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @NienKhoa AND Q.MaDonVi = @MaDonVi
              AND Q.LopHocID = @LopHocID AND Q.Thu = @Thu AND Q.BuoiID = @BuoiID AND Q.Tiet = @Tiet
              AND (Q.HieuLucTuNgay IS NOT NULL OR Q.HieuLucDenNgay IS NOT NULL)
        )
            RAISERROR(N'Không xác định được ngày áp dụng của tuần để kiểm tra quy tắc có giới hạn ngày.', 16, 1);

        IF @CapHoc = 0 AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
            WHERE Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @NienKhoa AND Q.MaDonVi = @MaDonVi
              AND Q.LopHocID = @LopHocID AND Q.Thu = @Thu AND Q.BuoiID = @BuoiID AND Q.Tiet = @Tiet
              AND ((@NgayBatDauTuan IS NULL AND Q.HieuLucTuNgay IS NULL AND Q.HieuLucDenNgay IS NULL)
                   OR (@NgayBatDauTuan IS NOT NULL
                       AND (Q.HieuLucTuNgay IS NULL OR DATEADD(DAY, @Thu - 2, @NgayBatDauTuan) >= Q.HieuLucTuNgay)
                       AND (Q.HieuLucDenNgay IS NULL OR DATEADD(DAY, @Thu - 2, @NgayBatDauTuan) <= Q.HieuLucDenNgay)))
              AND (
                    (Q.LoaiQuyTac = 'MON_BAT_BUOC' AND UPPER(ISNULL(@MaMon, '')) <> UPPER(Q.MaMon))
                 OR (Q.LoaiQuyTac = 'TIET_HOC' AND (NULLIF(@MaMon, '') IS NULL OR UPPER(@MaMon) = 'KHAC'))
                 OR (Q.LoaiQuyTac = 'HOAT_DONG_KHAC' AND UPPER(ISNULL(@MaMon, '')) <> 'KHAC')
              )
        )
            RAISERROR(N'Tiết này vi phạm quy tắc cứng đang có hiệu lực cho lớp. Hãy kiểm tra danh sách quy tắc theo lớp.', 16, 1);

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
