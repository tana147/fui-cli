CREATE PROCEDURE spAPI_TkbTheoTuan_LichGV
    @Tuan       INT,
    @MaGV       VARCHAR(15),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Lich cua 1 GV theo TUAN (2026-09-04, phuc vu dialog GV bao bận/Đổi GV — hiển thị lưới để bấm
    -- chọn slot) — gom TREN TAT CA RunID kha thi gan nhat cua MOI khoi cho dung tuan nay, vi 1 GV co
    -- the day nhieu khoi (moi khoi 1 RunID rieng cho cung 1 tuan).
    ;WITH RunHienHanh AS (
        SELECT Khoi, MAX(RunID) AS RunID
        FROM tblTKB_ChayAutoLog
        WHERE TuanHienTai = @Tuan AND KhaThi = 1 AND Enable = 1
        GROUP BY Khoi
    )
    SELECT k.ID, k.RunID, r.Khoi, k.MaLop, k.MaMon, m.TenMon, k.MaGV, k.Thu, k.Buoi, k.Tiet
    FROM RunHienHanh r
    JOIN tblTKB_KetQuaXep k ON k.RunID = r.RunID AND k.MaGV = @MaGV
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    ORDER BY k.Thu, k.Buoi, k.Tiet;
END
