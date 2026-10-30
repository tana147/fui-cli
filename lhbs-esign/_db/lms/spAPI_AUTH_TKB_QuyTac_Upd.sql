CREATE PROCEDURE dbo.spAPI_AUTH_TKB_QuyTac_Upd
    @QuyTacID INT,
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
        RAISERROR(N'[Unauthorized]Bạn không có quyền cập nhật quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    SET @LoaiQuyTac = UPPER(LTRIM(RTRIM(ISNULL(@LoaiQuyTac, ''))));
    SET @MaMon = NULLIF(LTRIM(RTRIM(@MaMon)), '');
    SET @MucDo = UPPER(LTRIM(RTRIM(ISNULL(@MucDo, 'CUNG'))));
    SET @MucUuTien = CASE WHEN @MucDo = 'CUNG' THEN 1 ELSE ISNULL(@MucUuTien, 3) END;

    DECLARE @NienKhoa VARCHAR(20), @MaDonVi INT;
    SELECT @NienKhoa = NienKhoa, @MaDonVi = MaDonVi
    FROM dbo.tblTKB_QuyTac WITH (UPDLOCK, HOLDLOCK)
    WHERE QuyTacID = @QuyTacID AND Enable = 1;
    IF @NienKhoa IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy quy tắc cần cập nhật.', 16, 1);
        RETURN;
    END;
    IF ISNULL(@LopHocID, 0) <= 0 OR NULLIF(LTRIM(RTRIM(@Lop)), '') IS NULL
       OR @Thu NOT BETWEEN 2 AND 7 OR @BuoiID NOT IN (1, 2) OR @Tiet NOT BETWEEN 1 AND 5
    BEGIN
        RAISERROR(N'Lớp, thứ, buổi hoặc tiết không hợp lệ.', 16, 1);
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
        WHERE Enable = 1 AND QuyTacID <> @QuyTacID AND NienKhoa = @NienKhoa
          AND MaDonVi = @MaDonVi AND LopHocID = @LopHocID AND Thu = @Thu
          AND BuoiID = @BuoiID AND Tiet = @Tiet
          AND COALESCE(HieuLucTuNgay, @NgayNamHoc) <= @HieuLucDen
          AND COALESCE(HieuLucDenNgay, @NgayCuoiNam) >= @HieuLucTu
    )
    BEGIN
        RAISERROR(N'Lớp đã có quy tắc trùng ô trong khoảng ngày hiệu lực này. Hãy chỉnh ngày kết thúc quy tắc cũ hoặc chọn khoảng khác.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.tblTKB_QuyTac
    SET LopHocID = @LopHocID, Lop = LTRIM(RTRIM(@Lop)), Thu = @Thu, BuoiID = @BuoiID,
        Tiet = @Tiet, LoaiQuyTac = @LoaiQuyTac, MaMon = @MaMon,
        TenMonHoc = CASE WHEN @LoaiQuyTac = 'HOAT_DONG_KHAC' THEN N'Hoạt động khác' ELSE @TenMonHoc END,
        MucDo = @MucDo, MucUuTien = @MucUuTien,
        HieuLucTuNgay = @HieuLucTuNgay, HieuLucDenNgay = @HieuLucDenNgay,
        GhiChu = @GhiChu, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE QuyTacID = @QuyTacID AND Enable = 1;

    SELECT @QuyTacID AS QuyTacID;
END
