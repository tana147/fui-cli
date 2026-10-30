CREATE PROCEDURE spAPI_TkbMonHocInsert
    @MaMon          varchar(15),
    @TenMon         nvarchar(100),
    @HeSo           float,
    @BatBuocXepDoi  bit,
    @UuTienXepDoi   bit,
    @sys_UserID     varchar(9)
AS
BEGIN
    IF @MaMon = '' OR @TenMon = ''
    BEGIN
        RAISERROR(N'Thiếu Mã môn hoặc Tên môn', 16, 1)
        RETURN
    END
    IF EXISTS (SELECT 1 FROM tblTKB_MonHoc WHERE MaMon = @MaMon)
    BEGIN
        RAISERROR(N'Mã môn đã tồn tại', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_MonHoc (MaMon, TenMon, HeSo, BatBuocXepDoi, UuTienXepDoi, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaMon, @TenMon, @HeSo, @BatBuocXepDoi, @UuTienXepDoi, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = @MaMon
END
