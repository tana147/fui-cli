CREATE PROCEDURE spAPI_TkbPhongLopMonLuu
    @MaLop VARCHAR(15),
    @MaMon VARCHAR(20),
    @MaPhong VARCHAR(20),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    -- 2026-10-09: luu phong co dinh cua 1 lop theo 1 mon (tab "Phong lop - mon"). @MaPhong rong = tat (lop hoc tai lop /
    -- dung chung nhom phong). Ap dung cho cac lan xep SAU (spAPI_TkbChayAuto #PoolLop) va gan phong khi Chay nhanh xong.
    SET NOCOUNT ON;
    SET @MaPhong = LTRIM(RTRIM(ISNULL(@MaPhong, '')));
    IF NOT EXISTS (SELECT 1 FROM tblTKB_Lop WHERE MaLop = @MaLop)
    BEGIN SELECT CAST(0 AS BIT) AS Success, N'Không có lớp ' + ISNULL(@MaLop, '') AS Message; RETURN; END
    IF @MaPhong <> '' AND NOT EXISTS (SELECT 1 FROM tblTKB_PhongHoc WHERE MaPhong = @MaPhong AND Enable = 1)
    BEGIN SELECT CAST(0 AS BIT) AS Success, N'Không có phòng ' + @MaPhong AS Message; RETURN; END
    DECLARE @Ghi NVARCHAR(200) = N'Sửa tay ' + ISNULL(@sys_UserID, '') + N' ' + FORMAT(GETDATE(), 'dd/MM/yyyy HH:mm');
    IF @MaPhong = ''
        UPDATE tblTKB_PhongLopMon SET Enable = 0, GhiChu = @Ghi WHERE MaLop = @MaLop AND MaMon = @MaMon;
    ELSE IF EXISTS (SELECT 1 FROM tblTKB_PhongLopMon WHERE MaLop = @MaLop AND MaMon = @MaMon)
        UPDATE tblTKB_PhongLopMon SET MaPhong = @MaPhong, Enable = 1, GhiChu = @Ghi WHERE MaLop = @MaLop AND MaMon = @MaMon;
    ELSE
        INSERT tblTKB_PhongLopMon (MaLop, MaMon, MaPhong, GhiChu, Enable, CreateUser) VALUES (@MaLop, @MaMon, @MaPhong, @Ghi, 1, LEFT(@sys_UserID, 50));
    SELECT CAST(1 AS BIT) AS Success,
           N'Đã lưu: ' + @MaLop + N' · ' + @MaMon + N' → ' + CASE WHEN @MaPhong = '' THEN N'không gán phòng' ELSE @MaPhong END
           + N' (áp dụng cho các lần xếp sau)' AS Message;
END
