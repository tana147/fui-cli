CREATE PROCEDURE spAPI_TkbChayAutoKhongXepDuocList
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT k.MaLop, k.MaMon, m.TenMon, k.MaGV, gv.HoTen AS TenGV, k.SoTiet
    FROM tblTKB_ChayAutoKhongXepDuoc k
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    WHERE k.RunID = @RunID
    ORDER BY k.MaLop, k.MaMon;
END