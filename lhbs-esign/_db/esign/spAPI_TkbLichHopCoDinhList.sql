CREATE PROCEDURE spAPI_TkbLichHopCoDinhList
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, LoaiNhom, MaNhom, TenNhom, Thu, Buoi, TietList, GhiChu
    FROM tblTKB_LichHopCoDinh
    WHERE Enable = 1
    ORDER BY LoaiNhom, MaNhom;
END