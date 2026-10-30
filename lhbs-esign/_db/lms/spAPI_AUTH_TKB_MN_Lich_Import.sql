CREATE PROCEDURE dbo.spAPI_AUTH_TKB_MN_Lich_Import
    @NienKhoa VARCHAR(20),
    @MaDonVi INT,
    @CapHoc INT,
    @HocKy INT,
    @TuanID INT,
    @Rows NVARCHAR(MAX),
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền nhập thời khóa biểu.', 16, 1);
        RETURN;
    END;
    IF ISJSON(@Rows) <> 1
    BEGIN
        RAISERROR(N'Dữ liệu import không phải JSON hợp lệ.', 16, 1);
        RETURN;
    END;
    IF NULLIF(LTRIM(RTRIM(@NienKhoa)), '') IS NULL OR ISNULL(@MaDonVi, 0) <= 0
    BEGIN
        RAISERROR(N'Vui lòng chọn năm học và cơ sở hợp lệ trước khi nhập.', 16, 1);
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @LockResult INT;
        EXEC @LockResult = sys.sp_getapplock
            @Resource = N'TKB-PRESCHOOL-SCHEDULE-WRITE',
            @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 10000;
        IF @LockResult < 0 RAISERROR(N'Không khóa được lịch để nhập. Vui lòng thử lại.', 16, 1);

    DECLARE @JsonRows NVARCHAR(MAX) = @Rows;
    IF LEFT(LTRIM(@Rows), 1) = '{' AND JSON_QUERY(@Rows, '$.Rows') IS NOT NULL
        SET @JsonRows = JSON_QUERY(@Rows, '$.Rows');

    DECLARE @ImportRows TABLE
    (
        LopHocID INT NULL, Lop NVARCHAR(200) NULL, Thu INT NULL, BuoiID INT NULL, Tiet INT NULL,
        MonHocID INT NULL, MaMon VARCHAR(50) NULL, TenMonHoc NVARCHAR(200) NULL,
        GiaoVienID VARCHAR(50) NULL, GhiChu NVARCHAR(MAX) NULL,
        ThoiKhoaBieu_CalenID VARCHAR(50) NULL, TuanID INT NULL
    );

    INSERT INTO @ImportRows
        (LopHocID, Lop, Thu, BuoiID, Tiet, MonHocID, MaMon, TenMonHoc, GiaoVienID, GhiChu, ThoiKhoaBieu_CalenID, TuanID)
    SELECT COALESCE(NULLIF(J.LopHocID, 0), H.LopHocID), J.Lop, J.Thu, J.BuoiID, J.Tiet,
           J.MonHocID, J.MaMon, J.TenMonHoc, J.GiaoVienID, J.GhiChu, J.ThoiKhoaBieu_CalenID, J.TuanID
    FROM OPENJSON(@JsonRows) WITH
    (
        LopHocID INT '$.LopHocID', Lop NVARCHAR(200) '$.Lop', Thu INT '$.Thu',
        BuoiID INT '$.BuoiID', Tiet INT '$.Tiet', MonHocID INT '$.MonHocID',
        MaMon VARCHAR(50) '$.MaMon', TenMonHoc NVARCHAR(200) '$.TenMonHoc',
        GiaoVienID VARCHAR(50) '$.GiaoVienID', GhiChu NVARCHAR(MAX) '$.GhiChu',
        ThoiKhoaBieu_CalenID VARCHAR(50) '$.ThoiKhoaBieu_CalenID', TuanID INT '$.TuanID'
    ) AS J
    OUTER APPLY
    (
        SELECT TOP (1) L.LopHocID
        FROM dbo.tblTKB_LopHoc AS L
        WHERE L.NamHoc = @NienKhoa
          AND LOWER(LTRIM(RTRIM(L.TenLop))) = LOWER(LTRIM(RTRIM(J.Lop)))
        ORDER BY L.LopHocID
    ) AS H;

    IF NOT EXISTS (SELECT 1 FROM @ImportRows)
    BEGIN
        RAISERROR(N'Không có dòng hợp lệ để nhập.', 16, 1);
        RETURN;
    END;

    DECLARE @SelectedTuanID INT = NULLIF(@TuanID, 0);
    IF @SelectedTuanID IS NULL
        SELECT TOP (1) @SelectedTuanID = NULLIF(TuanID, 0) FROM @ImportRows WHERE TuanID IS NOT NULL;
    IF @SelectedTuanID IS NULL
    BEGIN
        RAISERROR(N'Vui lòng chọn tuần học trước khi nhập thời khóa biểu.', 16, 1);
        RETURN;
    END;
    SET @CapHoc = ISNULL(@CapHoc, 0);
    DECLARE @NgayBatDauTuan DATE = NULL;
    SELECT @NgayBatDauTuan = NgayBatDau
    FROM dbo.tblTuanHocTap WITH (NOLOCK)
    WHERE TuanHocID = @SelectedTuanID;

    IF EXISTS
    (
        SELECT 1 FROM @ImportRows
        WHERE NULLIF(LTRIM(RTRIM(Lop)), N'') IS NULL
           OR Thu NOT BETWEEN 2 AND 7 OR BuoiID NOT IN (1, 2) OR Tiet NOT BETWEEN 1 AND 5
    )
    BEGIN
        RAISERROR(N'File có lớp hoặc vị trí tiết học không hợp lệ.', 16, 1);
        RETURN;
    END;

    UPDATE @ImportRows
    SET MonHocID = NULL, MaMon = 'KHAC', TenMonHoc = N'Hoạt động khác'
    WHERE UPPER(LTRIM(RTRIM(ISNULL(MaMon, '')))) = 'KHAC';

    -- Cặp hai tiết đầu buổi chiều cho phép môn học/giờ ăn theo cả hai thứ tự.
    IF @CapHoc = 0 AND EXISTS
    (
        SELECT 1
        FROM @ImportRows AS P1
        INNER JOIN @ImportRows AS P2
            ON ((P1.LopHocID = P2.LopHocID) OR (P1.LopHocID IS NULL AND P2.LopHocID IS NULL AND P1.Lop = P2.Lop))
           AND P1.Thu = P2.Thu AND P1.BuoiID = 2 AND P1.Tiet = 1 AND P2.BuoiID = 2 AND P2.Tiet = 2
        WHERE (
                (UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P1.MaMon)), ''), '')) = 'KHAC'
                 AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P2.MaMon)), ''), '')) = 'KHAC')
             OR (NULLIF(LTRIM(RTRIM(P1.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P1.MaMon))) <> 'KHAC'
                 AND NULLIF(LTRIM(RTRIM(P2.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P2.MaMon))) <> 'KHAC')
             OR NULLIF(LTRIM(RTRIM(P1.MaMon)), '') IS NULL OR NULLIF(LTRIM(RTRIM(P2.MaMon)), '') IS NULL
        )
    )
    BEGIN
        RAISERROR(N'Hai tiết đầu buổi chiều cần có một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);
        RETURN;
    END;
    IF @CapHoc = 0 AND EXISTS
    (
        SELECT 1 FROM @ImportRows AS R
        WHERE R.BuoiID = 2 AND R.Tiet >= 3
          AND NOT EXISTS
          (
              SELECT 1 FROM @ImportRows AS P1
              INNER JOIN @ImportRows AS P2
                  ON ((P1.LopHocID = P2.LopHocID) OR (P1.LopHocID IS NULL AND P2.LopHocID IS NULL AND P1.Lop = P2.Lop))
                 AND P1.Thu = P2.Thu AND P1.BuoiID = 2 AND P1.Tiet = 1 AND P2.BuoiID = 2 AND P2.Tiet = 2
              WHERE ((P1.LopHocID = R.LopHocID) OR (P1.LopHocID IS NULL AND R.LopHocID IS NULL AND P1.Lop = R.Lop))
                AND P1.Thu = R.Thu
                AND (
                        (UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P1.MaMon)), ''), '')) = 'KHAC'
                         AND NULLIF(LTRIM(RTRIM(P2.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P2.MaMon))) <> 'KHAC')
                     OR (NULLIF(LTRIM(RTRIM(P1.MaMon)), '') IS NOT NULL AND UPPER(LTRIM(RTRIM(P1.MaMon))) <> 'KHAC'
                         AND UPPER(ISNULL(NULLIF(LTRIM(RTRIM(P2.MaMon)), ''), '')) = 'KHAC')
                )
          )
    )
    BEGIN
        RAISERROR(N'Trước tiết chiều thứ 3 trở đi phải có đủ hai tiết đầu: một tiết học và một tiết ăn/Hoạt động khác.', 16, 1);
        RETURN;
    END;

    IF @CapHoc = 0 AND @NgayBatDauTuan IS NULL AND EXISTS
    (
        SELECT 1 FROM @ImportRows AS R
        INNER JOIN dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
            ON Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @NienKhoa AND Q.MaDonVi = @MaDonVi
           AND Q.LopHocID = R.LopHocID AND Q.Thu = R.Thu AND Q.BuoiID = R.BuoiID AND Q.Tiet = R.Tiet
           AND (Q.HieuLucTuNgay IS NOT NULL OR Q.HieuLucDenNgay IS NOT NULL)
    )
    BEGIN
        RAISERROR(N'Không xác định được ngày áp dụng của tuần để kiểm tra quy tắc có giới hạn ngày.', 16, 1);
        RETURN;
    END;

    IF @CapHoc = 0 AND EXISTS
    (
        SELECT 1
        FROM @ImportRows AS R
        INNER JOIN dbo.tblTKB_QuyTac AS Q WITH (UPDLOCK, HOLDLOCK)
            ON Q.Enable = 1 AND Q.MucDo = 'CUNG' AND Q.NienKhoa = @NienKhoa AND Q.MaDonVi = @MaDonVi
           AND Q.LopHocID = R.LopHocID AND Q.Thu = R.Thu AND Q.BuoiID = R.BuoiID AND Q.Tiet = R.Tiet
           AND ((@NgayBatDauTuan IS NULL AND Q.HieuLucTuNgay IS NULL AND Q.HieuLucDenNgay IS NULL)
                OR (@NgayBatDauTuan IS NOT NULL
                    AND (Q.HieuLucTuNgay IS NULL OR DATEADD(DAY, R.Thu - 2, @NgayBatDauTuan) >= Q.HieuLucTuNgay)
                    AND (Q.HieuLucDenNgay IS NULL OR DATEADD(DAY, R.Thu - 2, @NgayBatDauTuan) <= Q.HieuLucDenNgay)))
        WHERE (Q.LoaiQuyTac = 'MON_BAT_BUOC' AND UPPER(ISNULL(R.MaMon, '')) <> UPPER(Q.MaMon))
           OR (Q.LoaiQuyTac = 'TIET_HOC' AND (NULLIF(R.MaMon, '') IS NULL OR UPPER(R.MaMon) = 'KHAC'))
           OR (Q.LoaiQuyTac = 'HOAT_DONG_KHAC' AND UPPER(ISNULL(R.MaMon, '')) <> 'KHAC')
    )
    BEGIN
        RAISERROR(N'File import có tiết vi phạm quy tắc cứng đang có hiệu lực. Hãy kiểm tra danh sách quy tắc theo lớp.', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1 FROM @ImportRows AS A
        INNER JOIN @ImportRows AS B
            ON A.GiaoVienID = B.GiaoVienID AND A.Thu = B.Thu AND A.BuoiID = B.BuoiID AND A.Tiet = B.Tiet
           AND (A.LopHocID <> B.LopHocID OR A.Lop <> B.Lop)
        WHERE NULLIF(LTRIM(RTRIM(A.GiaoVienID)), '') IS NOT NULL
    )
    BEGIN
        RAISERROR(N'File import xếp một giáo viên ở hai lớp cùng thứ, buổi và tiết.', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1 FROM @ImportRows AS R
        INNER JOIN dbo.tblTKB_Lich AS L WITH (UPDLOCK, HOLDLOCK)
            ON L.NienKhoa = @NienKhoa AND L.Thu = R.Thu AND L.BuoiID = R.BuoiID AND L.Tiet = R.Tiet
           AND (L.GiaoVienID = R.GiaoVienID OR L.GiaoVienDayThayID = R.GiaoVienID)
           AND (L.TuanID IS NULL OR L.TuanID = 0 OR L.TuanID = @SelectedTuanID)
        WHERE NULLIF(LTRIM(RTRIM(R.GiaoVienID)), '') IS NOT NULL
          AND NOT (ISNULL(L.MaDonVi, 0) = @MaDonVi AND ISNULL(L.CapHoc, 0) = @CapHoc AND L.TuanID = @SelectedTuanID)
          AND NOT ((L.LopHocID = R.LopHocID) OR (L.LopHocID IS NULL AND L.Lop = R.Lop))
    )
    BEGIN
        RAISERROR(N'Giáo viên trong file import đã được xếp ở lớp khác cùng thứ, buổi và tiết.', 16, 1);
        RETURN;
    END;

    IF EXISTS
    (
        SELECT 1 FROM @ImportRows
        GROUP BY COALESCE(CONVERT(VARCHAR(20), LopHocID), LOWER(LTRIM(RTRIM(Lop)))), Thu, BuoiID, Tiet
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR(N'File import có nhiều dòng cho cùng một lớp và khung giờ.', 16, 1);
        RETURN;
    END;

        DELETE FROM dbo.tblTKB_Lich
        WHERE NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
          AND ISNULL(CapHoc, 0) = @CapHoc AND TuanID = @SelectedTuanID;

        INSERT INTO dbo.tblTKB_Lich
            (NienKhoa, HocKy, CapHoc, MaDonVi, TuanID, LopHocID, Lop, Thu, BuoiID, Tiet,
             MonHocID, MaMon, TenMonHoc, GiaoVienID, GhiChu, ThoiKhoaBieu_CalenID, NgayTao, NguoiTao)
        SELECT @NienKhoa, @HocKy, @CapHoc, @MaDonVi, @SelectedTuanID, R.LopHocID, R.Lop,
               R.Thu, R.BuoiID, R.Tiet, R.MonHocID, R.MaMon, R.TenMonHoc, R.GiaoVienID,
               R.GhiChu, NULLIF(R.ThoiKhoaBieu_CalenID, ''), GETDATE(), @sys_UserID
        FROM @ImportRows AS R;

        COMMIT TRANSACTION;

        SELECT L.TKBLichID, L.NienKhoa, L.HocKy, L.CapHoc, L.MaDonVi, L.TuanID,
               L.LopHocID, L.Lop, L.Thu, L.BuoiID, L.Tiet, L.MonHocID, L.MaMon,
               L.TenMonHoc, L.GiaoVienID, L.GhiChu, L.ThoiKhoaBieu_CalenID, L.NgayTao
        FROM dbo.tblTKB_Lich AS L WITH (NOLOCK)
        WHERE L.NienKhoa = @NienKhoa AND L.MaDonVi = @MaDonVi
          AND ISNULL(L.CapHoc, 0) = @CapHoc AND L.TuanID = @SelectedTuanID
        ORDER BY L.Thu, L.BuoiID, L.Tiet, L.Lop;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
        RETURN;
    END CATCH;
END
