CREATE PROCEDURE spAPI_TkbKetQuaXepPhongList
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT DISTINCT k.MaPhong, p.TenPhong
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_PhongHoc p ON p.MaPhong = k.MaPhong
    WHERE k.RunID = @RunID AND k.MaPhong IS NOT NULL
    ORDER BY k.MaPhong;
END