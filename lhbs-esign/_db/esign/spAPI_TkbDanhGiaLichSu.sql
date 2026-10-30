CREATE PROCEDURE spAPI_TkbDanhGiaLichSu
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-25: tien trinh danh gia theo Round cua 1 RunID (moi Moc da luu qua spAPI_TkbDanhGiaRun @Moc = ...).
    SELECT Moc, SUM(TongCan) AS TongCan, SUM(DaXep) AS DaXep, SUM(TongCan) - SUM(DaXep) AS Thieu,
           CAST(100.0 * SUM(DaXep) / NULLIF(SUM(TongCan), 0) AS DECIMAL(5, 1)) AS PhanTram,
           MAX(ThoiGian) AS ThoiGian
    FROM tblTKB_DanhGiaRound
    WHERE RunID = @RunID
    GROUP BY Moc
    ORDER BY MAX(ThoiGian);
END
