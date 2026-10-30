CREATE PROCEDURE spAPI_TkbKhoaPhongDungChungInsert
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
    INSERT INTO tblTKB_KhoaPhongDungChung (LoaiKhoa, TenKhoa, MaCap, Thu, Buoi, TietTu, TietDen, GhiChu, CreateUser, CreateTime, UpdateUser, UpdateTime, Enable)
    VALUES (@LoaiKhoa, @TenKhoa, @MaCap, @Thu, @Buoi, @TietTu, @TietDen, @GhiChu, @sys_UserID, GETDATE(), @sys_UserID, GETDATE(), 1)
    SELECT mess = N'Đã thêm'
END