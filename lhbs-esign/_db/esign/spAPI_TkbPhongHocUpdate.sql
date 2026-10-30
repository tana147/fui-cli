CREATE PROCEDURE spAPI_TkbPhongHocUpdate
    @MaPhong                varchar(10),
    @TenPhong               nvarchar(100),
    @KieuPhong              nvarchar(30),
    @MonHocChoPhep          nvarchar(500),
    @SucChuaToiDa_TieuHoc   int,
    @SucChuaToiDa_MamNon    int,
    @sys_UserID             varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_PhongHoc WHERE MaPhong = @MaPhong AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy phòng cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_PhongHoc
    SET TenPhong = @TenPhong,
        KieuPhong = @KieuPhong,
        MonHocChoPhep = @MonHocChoPhep,
        SucChuaToiDa_TieuHoc = @SucChuaToiDa_TieuHoc,
        SucChuaToiDa_MamNon = @SucChuaToiDa_MamNon,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaPhong = @MaPhong

    SELECT mess = N'Cập nhật thành công', id = @MaPhong
END
