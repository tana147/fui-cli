CREATE PROCEDURE dbo.spAPI_AUTH_TKB_MN_Lich_Upd
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
        RAISERROR(N'[Unauthorized]Bạn không có quyền chỉnh sửa thời khóa biểu.', 16, 1);
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
        IF UPPER(ISNULL(@MaMon, '')) = 'KHAC'
        BEGIN
            SET @MaMon = 'KHAC';
            SET @MonHocID = NULL;
            SET @TenMonHoc = N'Hoạt động khác';
        END;

        IF NULLIF(LTRIM(RTRIM(@Lop)), N'') IS NULL
           OR @Thu NOT BETWEEN 2 AND 7 OR @BuoiID NOT IN (1, 2) OR @Tiet NOT BETWEEN 1 AND 5
            RAISERROR(N'Lớp, thứ, buổi hoặc tiết không hợp lệ.', 16, 1);

        DECLARE @NgayBatDauTuan DATE = NULL, @NgayBatDauTuanCu DATE = NULL;
        IF @TuanID IS NOT NULL
            SELECT @NgayBatDauTuan = NgayBatDau FROM dbo.tblTuanHocTap WITH (NOLOCK) WHERE TuanHocID = @TuanID;
        IF @OldTuanID IS NOT NULL
            SELECT @NgayBatDauTuanCu = NgayBatDau FROM dbo.tblTuanHocTap WITH (NOLOCK) WHERE TuanHocID = @OldTuanID;

        IF @OldCapHoc = 0 AND @NgayBatDauTuanCu IS NULL AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
            WHERE Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @OldNienKhoa AND Q.MaDonVi = @OldMaDonVi
              AND Q.LopHocID = @OldLopHocID AND Q.Thu = @OldThu AND Q.BuoiID = @OldBuoiID AND Q.Tiet = @OldTiet
              AND (Q.HieuLucTuNgay IS NOT NULL OR Q.HieuLucDenNgay IS NOT NULL)
        )
            RAISERROR(N'Không xác định được tuần cũ để kiểm tra quy tắc có giới hạn ngày.', 16, 1);

        -- Cho phép đổi thứ tự học/ăn ở tiết 1 và 2; khi đã có cả hai thì bắt buộc khác loại.
        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet IN (1, 2) AND EXISTS
        (
            SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
            WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
              AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
              AND Thu = @Thu AND BuoiID = 2 AND Tiet = CASE WHEN @Tiet = 1 THEN 2 ELSE 1 END
              AND TKBLichID <> @TKBLichID
              AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
              AND NOT (
                    (UPPER(ISNULL(@MaMon, '')) = 'KHAC'
                     AND NULLIF(LTRIM(RTRIM(MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(MaMon))) <> 'KHAC')
                 OR (NULLIF(@MaMon, '') IS NOT NULL AND UPPER(@MaMon) <> 'KHAC'
                     AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(MaMon)), ''), '')) = 'KHAC')
              )
        )
            RAISERROR(N'Hai tiết đầu buổi chiều cần có một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);

        IF @CapHoc = 0 AND @BuoiID = 2 AND @Tiet IN (1, 2)
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet >= 3 AND TKBLichID <> @TKBLichID
                 AND (TuanID IS NULL OR TuanID = 0 OR @TuanID IS NULL OR TuanID = @TuanID)
           )
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
                 AND ((LopHocID = @LopHocID) OR (LopHocID IS NULL AND Lop = @Lop))
                 AND Thu = @Thu AND BuoiID = 2 AND Tiet = CASE WHEN @Tiet = 1 THEN 2 ELSE 1 END
                 AND TKBLichID <> @TKBLichID
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
            SELECT 1 FROM dbo.tblTKB_Lich AS P1 WITH (UPDLOCK, HOLDLOCK)
            INNER JOIN dbo.tblTKB_Lich AS P2 WITH (UPDLOCK, HOLDLOCK)
                ON P2.NienKhoa = P1.NienKhoa AND P2.MaDonVi = P1.MaDonVi
               AND ((P2.LopHocID = P1.LopHocID) OR (P2.LopHocID IS NULL AND P1.LopHocID IS NULL AND P2.Lop = P1.Lop))
               AND P2.Thu = P1.Thu AND P2.BuoiID = 2 AND P2.Tiet = 2
               AND (P2.TuanID IS NULL OR P2.TuanID = 0 OR @TuanID IS NULL OR P2.TuanID = @TuanID)
            WHERE P1.TKBLichID <> @TKBLichID AND P2.TKBLichID <> @TKBLichID
              AND P1.NienKhoa = @NienKhoa AND P1.MaDonVi = @MaDonVi
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

        -- Khi một trong hai tiết đầu rời khỏi lớp/ngày cũ, các tiết sau phải còn một cặp hợp lệ.
        IF @OldCapHoc = 0 AND @OldBuoiID = 2 AND @OldTiet IN (1, 2)
           AND NOT (@CapHoc = 0 AND @NienKhoa = @OldNienKhoa AND @MaDonVi = @OldMaDonVi
                    AND ((@LopHocID = @OldLopHocID) OR (@LopHocID IS NULL AND @OldLopHocID IS NULL AND @Lop = @OldLop))
                    AND @Thu = @OldThu AND @BuoiID = @OldBuoiID
                    AND ISNULL(@TuanID, -1) = ISNULL(@OldTuanID, -1))
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich WITH (UPDLOCK, HOLDLOCK)
               WHERE NienKhoa = @OldNienKhoa AND MaDonVi = @OldMaDonVi
                 AND ((LopHocID = @OldLopHocID) OR (LopHocID IS NULL AND Lop = @OldLop))
                 AND Thu = @OldThu AND BuoiID = 2 AND Tiet >= 3 AND TKBLichID <> @TKBLichID
                 AND (TuanID IS NULL OR TuanID = 0 OR @OldTuanID IS NULL OR TuanID = @OldTuanID)
           )
           AND NOT EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_Lich AS P1 WITH (UPDLOCK, HOLDLOCK)
               INNER JOIN dbo.tblTKB_Lich AS P2 WITH (UPDLOCK, HOLDLOCK)
                   ON P2.NienKhoa = P1.NienKhoa AND P2.MaDonVi = P1.MaDonVi
                  AND ((P2.LopHocID = P1.LopHocID) OR (P2.LopHocID IS NULL AND P1.LopHocID IS NULL AND P2.Lop = P1.Lop))
                  AND P2.Thu = P1.Thu AND P2.BuoiID = 2 AND P2.Tiet = 2
                  AND (P2.TuanID IS NULL OR P2.TuanID = 0 OR @OldTuanID IS NULL OR P2.TuanID = @OldTuanID)
               WHERE P1.TKBLichID <> @TKBLichID AND P2.TKBLichID <> @TKBLichID
                 AND P1.NienKhoa = @OldNienKhoa AND P1.MaDonVi = @OldMaDonVi
                 AND ((P1.LopHocID = @OldLopHocID) OR (P1.LopHocID IS NULL AND P1.Lop = @OldLop))
                 AND P1.Thu = @OldThu AND P1.BuoiID = 2 AND P1.Tiet = 1
                 AND (P1.TuanID IS NULL OR P1.TuanID = 0 OR @OldTuanID IS NULL OR P1.TuanID = @OldTuanID)
                 AND (
                       (UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P1.MaMon)), ''), '')) = 'KHAC'
                        AND NULLIF(LTRIM(RTRIM(P2.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P2.MaMon))) <> 'KHAC')
                    OR (NULLIF(LTRIM(RTRIM(P1.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P1.MaMon))) <> 'KHAC'
                        AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P2.MaMon)), ''), '')) = 'KHAC')
                 )
           )
            RAISERROR(N'Không thể chuyển tiết đầu buổi chiều khỏi lớp cũ khi các tiết phía sau chưa có đủ cặp tiết 1 và 2 hợp lệ.', 16, 1);

        -- Nếu tiết có rule cứng đang hiệu lực, không cho chuyển/xóa làm trống ô bắt buộc.
        IF @OldCapHoc = 0
           AND NOT (@CapHoc = 0 AND @NienKhoa = @OldNienKhoa AND @MaDonVi = @OldMaDonVi
                    AND ((@LopHocID = @OldLopHocID) OR (@LopHocID IS NULL AND @OldLopHocID IS NULL AND @Lop = @OldLop))
                    AND @Thu = @OldThu AND @BuoiID = @OldBuoiID AND @Tiet = @OldTiet
                    AND ISNULL(@TuanID, -1) = ISNULL(@OldTuanID, -1))
           AND @OldBuoiID IS NOT NULL
           AND EXISTS
           (
               SELECT 1 FROM dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
               WHERE Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @OldNienKhoa AND Q.MaDonVi = @OldMaDonVi
                 AND Q.LopHocID = @OldLopHocID AND Q.Thu = @OldThu AND Q.BuoiID = @OldBuoiID AND Q.Tiet = @OldTiet
                 AND ((@NgayBatDauTuanCu IS NULL AND Q.HieuLucTuNgay IS NULL AND Q.HieuLucDenNgay IS NULL)
                      OR (@NgayBatDauTuanCu IS NOT NULL
                          AND (Q.HieuLucTuNgay IS NULL OR DATEADD(DAY, @OldThu - 2, @NgayBatDauTuanCu) >= Q.HieuLucTuNgay)
                          AND (Q.HieuLucDenNgay IS NULL OR DATEADD(DAY, @OldThu - 2, @NgayBatDauTuanCu) <= Q.HieuLucDenNgay)))
           )
            RAISERROR(N'Không thể chuyển tiết khỏi ô đang có quy tắc cứng còn hiệu lực.', 16, 1);

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
