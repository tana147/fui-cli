CREATE PROCEDURE spAPI_TkbMonHocUpdate
    @MaMon          varchar(15),
    @TenMon         nvarchar(100),
    @HeSo           float,
    @BatBuocXepDoi  bit,
    @UuTienXepDoi   bit,
    @sys_UserID     varchar(9)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblTKB_MonHoc WHERE MaMon = @MaMon AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy môn học cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_MonHoc
    SET TenMon = @TenMon,
        HeSo = @HeSo,
        BatBuocXepDoi = @BatBuocXepDoi,
        UuTienXepDoi = @UuTienXepDoi,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE MaMon = @MaMon

    SELECT mess = N'Cập nhật thành công', id = @MaMon
END
