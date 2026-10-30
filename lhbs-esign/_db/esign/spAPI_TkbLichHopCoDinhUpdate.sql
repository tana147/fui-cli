CREATE PROCEDURE spAPI_TkbLichHopCoDinhUpdate
    @ID INT,
    @LoaiNhom VARCHAR(20),
    @MaNhom VARCHAR(20),
    @TenNhom NVARCHAR(150),
    @Thu INT,
    @Buoi VARCHAR(10),
    @TietList VARCHAR(50),
    @GhiChu NVARCHAR(300) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_LichHopCoDinh
    SET LoaiNhom = @LoaiNhom, MaNhom = @MaNhom, TenNhom = @TenNhom, Thu = @Thu,
        Buoi = @Buoi, TietList = @TietList, GhiChu = @GhiChu
    WHERE ID = @ID
    SELECT mess = N'Đã cập nhật'
END