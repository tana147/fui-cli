CREATE PROCEDURE spAPI_TkbKhoaPhongDungChungList
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, LoaiKhoa, TenKhoa, MaCap, Thu, Buoi, TietTu, TietDen, GhiChu
    FROM tblTKB_KhoaPhongDungChung
    WHERE Enable = 1
    ORDER BY Thu, Buoi, TietTu;
END