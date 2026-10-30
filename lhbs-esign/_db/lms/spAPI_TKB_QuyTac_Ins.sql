CREATE PROCEDURE dbo.spAPI_TKB_QuyTac_Ins
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
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền thêm quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    SET @LoaiQuyTac = UPPER(LTRIM(RTRIM(ISNULL(@LoaiQuyTac, ''))));
    SET @MaMon = NULLIF(LTRIM(RTRIM(@MaMon)), '');

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
    IF @LoaiQuyTac = 'HOAT_DONG_KHAC' AND (@BuoiID <> 2 OR @Tiet <> 1)
    BEGIN
        RAISERROR(N'Hoạt động khác chỉ áp dụng ở tiết 1 buổi chiều.', 16, 1);
        RETURN;
    END;
    IF EXISTS
    (
        SELECT 1 FROM dbo.tblTKB_QuyTac WITH (UPDLOCK, HOLDLOCK)
        WHERE Enable = 1 AND NienKhoa = @NienKhoa AND MaDonVi = @MaDonVi
          AND LopHocID = @LopHocID AND Thu = @Thu AND BuoiID = @BuoiID AND Tiet = @Tiet
    )
    BEGIN
        RAISERROR(N'Lớp đã có quy tắc ở đúng thứ, buổi và tiết này.', 16, 1);
        RETURN;
    END;

    INSERT INTO dbo.tblTKB_QuyTac
        (NienKhoa, MaDonVi, LopHocID, Lop, Thu, BuoiID, Tiet, LoaiQuyTac, MaMon,
         TenMonHoc, GhiChu, CreateUser, UpdateUser)
    VALUES
        (@NienKhoa, @MaDonVi, @LopHocID, LTRIM(RTRIM(@Lop)), @Thu, @BuoiID, @Tiet,
         @LoaiQuyTac, @MaMon,
         CASE WHEN @LoaiQuyTac = 'HOAT_DONG_KHAC' THEN N'Hoạt động khác' ELSE @TenMonHoc END,
         @GhiChu, @sys_UserID, @sys_UserID);

    SELECT CONVERT(INT, SCOPE_IDENTITY()) AS QuyTacID;
END
