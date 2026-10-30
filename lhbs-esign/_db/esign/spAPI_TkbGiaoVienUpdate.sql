CREATE PROCEDURE spAPI_TkbGiaoVienUpdate
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
    IF NOT EXISTS (SELECT 1 FROM tblTKB_GiaoVien WHERE MaGV = @MaGV AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy giáo viên cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_GiaoVien
    SET HoTen = @HoTen,
        LaThinhGiang = @LaThinhGiang,
        BuoiBanCoDinh = @BuoiBanCoDinh,
        GhiChu = @GhiChu,
        NgaySinh = @NgaySinh,
        GioiTinh = @GioiTinh,
        PhongBanChucVu = @PhongBanChucVu,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaGV = @MaGV

    SELECT mess = N'Cập nhật thành công', id = @MaGV
END
