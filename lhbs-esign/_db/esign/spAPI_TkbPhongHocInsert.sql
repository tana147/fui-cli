CREATE PROCEDURE spAPI_TkbPhongHocInsert
    @MaPhong                varchar(10),
    @TenPhong               nvarchar(100),
    @KieuPhong              nvarchar(30),
    @MonHocChoPhep          nvarchar(500),
    @SucChuaToiDa_TieuHoc   int,
    @SucChuaToiDa_MamNon    int,
    @sys_UserID             varchar(9)
AS
BEGIN
    IF @MaPhong = '' OR @TenPhong = ''
    BEGIN
        RAISERROR(N'Thiếu Mã phòng hoặc Tên phòng', 16, 1)
        RETURN
    END
    IF EXISTS (SELECT 1 FROM tblTKB_PhongHoc WHERE MaPhong = @MaPhong)
    BEGIN
        RAISERROR(N'Mã phòng đã tồn tại', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_PhongHoc (MaPhong, TenPhong, KieuPhong, MonHocChoPhep, SucChuaToiDa_TieuHoc, SucChuaToiDa_MamNon, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaPhong, @TenPhong, @KieuPhong, @MonHocChoPhep, @SucChuaToiDa_TieuHoc, @SucChuaToiDa_MamNon, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = @MaPhong
END
