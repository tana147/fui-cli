CREATE PROCEDURE spAPI_TkbDayThayTietTheoThu
    @RunID INT,
    @MaGV VARCHAR(15),
    @NgayApDung DATE,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Chuan hoa thu trong tuan ve 1=Thu Hai...7=Chu Nhat bat ke @@DATEFIRST cua server, roi map
    -- sang quy uoc Thu cua he thong (Thu 2 = Thu Hai ... Thu 7 = Thu Bay).
    DECLARE @DowMon INT = ((DATEPART(WEEKDAY, @NgayApDung) + @@DATEFIRST - 2) % 7) + 1;
    DECLARE @Thu INT = @DowMon + 1;

    SELECT k.ID AS KetQuaXepID, k.MaLop, k.Buoi, k.Tiet, k.MaMon, m.TenMon,
           CASE WHEN EXISTS (
               SELECT 1 FROM tblTKB_DayThay dt
               WHERE dt.KetQuaXepID = k.ID AND dt.NgayApDung = @NgayApDung AND dt.Enable = 1
           ) THEN 1 ELSE 0 END AS DaDanhDauVang
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    WHERE k.RunID = @RunID AND k.MaGV = @MaGV AND k.Thu = @Thu AND k.MaMon <> 'HOP'
    ORDER BY k.Buoi, k.Tiet;
END