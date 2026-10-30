CREATE PROCEDURE spAPI_TkbKetQuaXepGVList
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT k.MaGV, gv.HoTen AS TenGV
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    WHERE k.RunID = @RunID
    ORDER BY gv.HoTen;
END