CREATE PROCEDURE spAPI_StemPhanCongUpdate
    @StemPhanCongID bigint,
    @ThuTuTuan      int,
    @Khoi           varchar(2),
    @MaLop          varchar(10),
    @MonPhuTrach    nvarchar(50),
    @ChuDe          nvarchar(300),
    @MaGV           varchar(15) = NULL,
    @sys_UserID     varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_StemPhanCong WHERE StemPhanCongID = @StemPhanCongID AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy phân công cần sửa', 16, 1)
        RETURN
    END

    IF @MaGV IS NULL OR @MaGV = ''
    BEGIN
        RAISERROR(N'Thiếu giáo viên', 16, 1)
        RETURN
    END

    DECLARE @TenGV nvarchar(100) = (SELECT HoTen FROM tblTKB_GiaoVien WHERE MaGV = @MaGV)
    IF @TenGV IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy giáo viên', 16, 1)
        RETURN
    END

    UPDATE tblTKB_StemPhanCong
    SET ThuTuTuan   = @ThuTuTuan,
        Khoi        = @Khoi,
        MaLop       = @MaLop,
        MonPhuTrach = @MonPhuTrach,
        ChuDe       = @ChuDe,
        TenGV       = @TenGV,
        MaGV        = @MaGV,
        UpdateUser  = @sys_UserID,
        UpdateTime  = GETDATE()
    WHERE StemPhanCongID = @StemPhanCongID

    SELECT mess = N'Cập nhật thành công', id = @StemPhanCongID
END
