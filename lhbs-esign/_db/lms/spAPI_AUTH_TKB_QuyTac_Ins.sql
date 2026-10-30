CREATE PROCEDURE dbo.spAPI_AUTH_TKB_QuyTac_Ins
    @NienKhoa VARCHAR(20),
    @MaDonVi INT,
    @LopHocID INT,
    @Lop VARCHAR(100),
    @Thu TINYINT,
    @BuoiID TINYINT,
    @Tiet TINYINT,
    @LoaiQuyTac VARCHAR(20),
    @MaMon VARCHAR(50),
    @TenMonHoc NVARCHAR(255),
    @GhiChu NVARCHAR(500),
    @sys_UserID VARCHAR(20),
    @sys_SystemRight INT,
    @MucDo VARCHAR(10),
    @MucUuTien TINYINT,
    @HieuLucTuNgay DATE,
    @HieuLucDenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'[Unauthorized]Bạn không có quyền thêm quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    SET @LoaiQuyTac = UPPER(LTRIM(RTRIM(ISNULL(@LoaiQuyTac, ''))));
    SET @MaMon = NULLIF(LTRIM(RTRIM(@MaMon)), '');
    SET @MucDo = UPPER(LTRIM(RTRIM(ISNULL(@MucDo, 'CUNG'))));
    SET @MucUuTien = CASE WHEN @MucDo = 'CUNG' THEN 1 ELSE ISNULL(@MucUuTien, 3) END;

    IF NULLIF(LTRIM(RTRIM(@NienKhoa)), '') IS NULL OR ISNULL(@MaDonVi, 0) <= 0
       OR ISNULL(@LopHocID, 0) <= 0 OR NULLIF(LTRIM(RTRIM(@Lop)), '') IS NULL
    BEGIN
        RAISERROR(N'Vui lòng chọn năm học, cơ sở và lớp hợp lệ.', 16, 1);
        RETURN;
    END;
    IF @Thu NOT BETWEEN 2 AND 7 OR @BuoiID NOT IN (1, 2) OR @Tiet NOT BETWEEN 1 AND 5
    BEGIN
        RAISERROR(N'Thứ, buổi hoặc tiết không hợp lệ.', 16, 1);
        RETURN;
    END;
    IF @LoaiQuyTac NOT IN ('MON_BAT_BUOC', 'TIET_HOC', 'HOAT_DONG_KHAC')
    BEGIN
        RAISERROR(N'Loại quy tắc không hợp lệ.', 16, 1);
        RETURN;
    END;
    IF @LoaiQuyTac = 'MON_BAT_BUOC'
       AND (@MaMon IS NULL OR NOT EXISTS (SELECT 1 FROM dbo.tblTKB_MonHoc WHERE MaMon = @MaMon))
    BEGIN
        RAISERROR(N'Vui lòng chọn mã môn hợp lệ cho quy tắc môn bắt buộc.', 16, 1);
        RETURN;
    END;
    IF @LoaiQuyTac <> 'MON_BAT_BUOC' AND @MaMon IS NOT NULL
    BEGIN
        RAISERROR(N'Chỉ quy tắc môn bắt buộc mới chọn mã môn.', 16, 1);
        RETURN;
    END;
    IF @LoaiQuyTac = 'HOAT_DONG_KHAC' AND (@BuoiID <> 2 OR @Tiet NOT IN (1, 2))
    BEGIN
        RAISERROR(N'Hoạt động khác chỉ áp dụng ở tiết 1 hoặc tiết 2 buổi chiều.', 16, 1);
        RETURN;
    END;
    IF @MucDo NOT IN ('CUNG', 'MEM') OR @MucUuTien NOT BETWEEN 1 AND 5
    BEGIN
        RAISERROR(N'Mức độ hoặc mức ưu tiên quy tắc không hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @NamBatDau INT = TRY_CONVERT(INT, @NienKhoa);
    DECLARE @NgayNamHoc DATE = CASE WHEN @NamBatDau BETWEEN 2000 AND 2100 THEN DATEFROMPARTS(@NamBatDau, 8, 1) END;
    DECLARE @NgayCuoiNam DATE = CASE WHEN @NgayNamHoc IS NOT NULL THEN DATEADD(DAY, -1, DATEADD(YEAR, 1, @NgayNamHoc)) END;
    DECLARE @HieuLucTu DATE = COALESCE(@HieuLucTuNgay, @NgayNamHoc);
    DECLARE @HieuLucDen DATE = COALESCE(@HieuLucDenNgay, @NgayCuoiNam);
    IF @NgayNamHoc IS NULL OR @HieuLucTu > @HieuLucDen
       OR @HieuLucTu < @NgayNamHoc OR @HieuLucDen > @NgayCuoiNam
    BEGIN
        RAISERROR(N'Khoảng hiệu lực phải nằm trong niên khóa và ngày bắt đầu không được sau ngày kết thúc.', 16, 1);
        RETURN;
    END;
    IF EXISTS
    (
        SELECT 1 FROM dbo.tblTKB_QuyTac WITH (UPDLOCK, HOLDLOCK)
        WHERE Enable = 1 AND NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
          AND LopHocID = @LopHocID AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
          AND COALESCE(HieuLucTuNgay, @NgayNamHoc) <= @HieuLucDen
          AND COALESCE(HieuLucDenNgay, @NgayCuoiNam) >= @HieuLucTu
    )
    BEGIN
        RAISERROR(N'Lớp đã có quy tắc trùng ô trong khoảng ngày hiệu lực này. Hãy chỉnh ngày kết thúc quy tắc cũ hoặc chọn khoảng khác.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.tblTKB_QuyTac
        (NienKhoa, MaDonVi, LopHocID, Lop, Thu, BuoiID, Tiet, LoaiQuyTac, MaMon,
         TenMonHoc, MucDo, MucUuTien, HieuLucTuNgay, HieuLucDenNgay, GhiChu, CreateUser, UpdateUser)
    VALUES
        (@NienKhoa, @MaDonVi, @LopHocID, LTRIM(RTRIM(@Lop)), @Thu, @BuoiID, @Tiet,
         @LoaiQuyTac, @MaMon,
         CASE WHEN @LoaiQuyTac = 'HOAT_DONG_KHAC' THEN N'Hoạt động khác' ELSE @TenMonHoc END,
         @MucDo, @MucUuTien, @HieuLucTuNgay, @HieuLucDenNgay, @GhiChu, @sys_UserID, @sys_UserID);

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS QuyTacID;
END
