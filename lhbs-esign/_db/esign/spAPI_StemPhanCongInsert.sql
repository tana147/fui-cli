CREATE PROCEDURE spAPI_StemPhanCongInsert
    @ThuTuTuan   int,
    @Khoi        varchar(2),
    @MaLop       varchar(10),
    @MonPhuTrach nvarchar(50),
    @ChuDe       nvarchar(300),
    @MaGV        varchar(15) = NULL,
    @sys_UserID  varchar(9)
AS
BEGIN
    IF @ThuTuTuan IS NULL OR @Khoi = '' OR @MaLop = '' OR @MaGV IS NULL OR @MaGV = ''
    BEGIN
        RAISERROR(N'Thiếu dữ liệu bắt buộc (Tuần, Khối, Lớp, Giáo viên)', 16, 1)
        RETURN
    END

    DECLARE @TenGV nvarchar(100) = (SELECT HoTen FROM tblTKB_GiaoVien WHERE MaGV = @MaGV)
    IF @TenGV IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy giáo viên', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_StemPhanCong (ThuTuTuan, Khoi, MaLop, MonPhuTrach, ChuDe, TenGV, MaGV, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@ThuTuTuan, @Khoi, @MaLop, @MonPhuTrach, @ChuDe, @TenGV, @MaGV, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = SCOPE_IDENTITY()
END
