CREATE PROCEDURE spAPI_TkbKhoaPhongDungChungUpdate
    @ID INT,
    @LoaiKhoa VARCHAR(30),
    @TenKhoa NVARCHAR(150),
    @MaCap VARCHAR(20) = NULL,
    @Thu INT,
    @Buoi VARCHAR(10),
    @TietTu INT,
    @TietDen INT,
    @GhiChu NVARCHAR(300) = NULL,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_KhoaPhongDungChung
    SET LoaiKhoa = @LoaiKhoa, TenKhoa = @TenKhoa, MaCap = @MaCap, Thu = @Thu, Buoi = @Buoi,
        TietTu = @TietTu, TietDen = @TietDen, GhiChu = @GhiChu,
        UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ID = @ID
    SELECT mess = N'Đã cập nhật'
END