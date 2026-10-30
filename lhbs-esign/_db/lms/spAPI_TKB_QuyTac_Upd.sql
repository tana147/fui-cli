CREATE PROCEDURE dbo.spAPI_TKB_QuyTac_Upd
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
    @sys_SystemRight INT
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@sys_SystemRight, 0) NOT IN (1, 9)
    BEGIN
        RAISERROR(N'Bạn không có quyền cập nhật quy tắc thời khóa biểu.', 16, 1);
        RETURN;
    END;

    SET @LoaiQuyTac = UPPER(LTRIM(RTRIM(ISNULL(@LoaiQuyTac, ''))));
    SET @MaMon = NULLIF(LTRIM(RTRIM(@MaMon)), '');

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
    IF @LoaiQuyTac = 'HOAT_DONG_KHAC' AND (@BuoiID <> 2 OR @Tiet <> 1)
    BEGIN
        RAISERROR(N'Hoạt động khác chỉ áp dụng ở tiết 1 buổi chiều.', 16, 1);
        RETURN;
    END;
    IF EXISTS
    (
        SELECT 1 FROM dbo.tblTKB_QuyTac
        WHERE Enable = 1 AND QuyTacID <> @QuyTacID AND NienKhoa = @NienKhoa
          AND MaDonVi = @MaDonVi AND LopHocID = @LopHocID AND Thu = @Thu
          AND BuoiID = @BuoiID AND Tiet = @Tiet
    )
    BEGIN
        RAISERROR(N'Lớp đã có quy tắc ở đúng thứ, buổi và tiết này.', 16, 1);
        RETURN;
    END;

    UPDATE dbo.tblTKB_QuyTac
    SET LopHocID = @LopHocID, Lop = LTRIM(RTRIM(@Lop)), Thu = @Thu, BuoiID = @BuoiID,
        Tiet = @Tiet, LoaiQuyTac = @LoaiQuyTac, MaMon = @MaMon,
        TenMonHoc = CASE WHEN @LoaiQuyTac = 'HOAT_DONG_KHAC' THEN N'Hoạt động khác' ELSE @TenMonHoc END,
        GhiChu = @GhiChu, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE QuyTacID = @QuyTacID AND Enable = 1;

    SELECT @QuyTacID AS QuyTacID;
END
