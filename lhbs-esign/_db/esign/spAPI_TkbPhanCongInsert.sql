CREATE PROCEDURE spAPI_TkbPhanCongInsert
    @MaGV               varchar(15),
    @MaLop              varchar(10),
    @MaMon              varchar(15),
    @SoTietChuanTuan    int,
    @HocKy              varchar(4) = 'HK1',
    @TuanApDungTu       int = NULL,
    @TuanApDungDen      int = NULL,
    @ApDungTuanChan     bit = NULL,
    @sys_UserID         varchar(9)
AS
BEGIN
    IF @MaGV = '' OR @MaLop = '' OR @MaMon = '' OR @SoTietChuanTuan IS NULL
    BEGIN
        RAISERROR(N'Thiếu GV, Lớp, Môn hoặc số tiết chuẩn', 16, 1)
        RETURN
    END
    IF EXISTS (SELECT 1 FROM tblTKB_PhanCongGiangDay WHERE MaGV = @MaGV AND MaLop = @MaLop AND MaMon = @MaMon AND HocKy = @HocKy AND Enable = 1)
    BEGIN
        RAISERROR(N'Phân công này đã tồn tại (trùng GV-Lớp-Môn-Học kỳ)', 16, 1)
        RETURN
    END

    INSERT INTO tblTKB_PhanCongGiangDay (MaGV, MaLop, MaMon, SoTietChuanTuan, HocKy, TuanApDungTu, TuanApDungDen, ApDungTuanChan, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@MaGV, @MaLop, @MaMon, @SoTietChuanTuan, @HocKy, @TuanApDungTu, @TuanApDungDen, @ApDungTuanChan, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)

    SELECT mess = N'Thêm thành công', id = SCOPE_IDENTITY()
END