CREATE PROCEDURE spAPI_TkbPhanCongUpdate
    @PhanCongID         bigint,
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
    IF NOT EXISTS (SELECT 1 FROM tblTKB_PhanCongGiangDay WHERE PhanCongID = @PhanCongID AND Enable = 1)
    BEGIN
        RAISERROR(N'Không tìm thấy phân công cần sửa', 16, 1)
        RETURN
    END

    UPDATE tblTKB_PhanCongGiangDay
    SET MaGV = @MaGV,
        MaLop = @MaLop,
        MaMon = @MaMon,
        SoTietChuanTuan = @SoTietChuanTuan,
        HocKy = @HocKy,
        TuanApDungTu = @TuanApDungTu,
        TuanApDungDen = @TuanApDungDen,
        ApDungTuanChan = @ApDungTuanChan,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE PhanCongID = @PhanCongID

    SELECT mess = N'Cập nhật thành công', id = @PhanCongID
END