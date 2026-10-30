CREATE PROCEDURE spAPI_TkbGiaoVienInsert
    @MaGV           varchar(15),
    @HoTen          nvarchar(100),
    @LaThinhGiang   bit,
    @BuoiBanCoDinh  nvarchar(200),
    @GhiChu         nvarchar(300),
    @NgaySinh       date = NULL,
    @GioiTinh       varchar(10) = NULL,
    @PhongBanChucVu nvarchar(100) = NULL,
    @sys_UserID     varchar(9)
AS
BEGIN
    IF @MaGV = '' OR @HoTen = ''
    BEGIN
        RAISERROR(N'Thiếu Mã GV hoặc Họ tên', 16, 1)
        RETURN
    END
    IF EXISTS (SELECT 1 FROM tblTKB_GiaoVien WHERE MaGV = @MaGV)
    BEGIN
        RAISERROR(N'Mã giáo viên đã tồn tại', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_GiaoVien (MaGV, HoTen, LaThinhGiang, BuoiBanCoDinh, GhiChu, NgaySinh, GioiTinh, PhongBanChucVu, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaGV, @HoTen, @LaThinhGiang, @BuoiBanCoDinh, @GhiChu, @NgaySinh, @GioiTinh, @PhongBanChucVu, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = @MaGV
END
