CREATE PROCEDURE spTkbGanPhongTheoLopMon
    @RunID INT
AS
BEGIN
    -- 2026-10-09: dien phong cho cac tiet chua co phong theo bang tblTKB_PhongLopMon (moi lop hoc 1 mon luon o
    -- 1 phong co dinh — rut tu TKB that tuan 10/8, 14/9, 21/9, 28/9). Phong solver da chon (pool Am nhac/Boi/
    -- thu vien/AI/STEM) giu nguyen. Goi tu dong khi Chay nhanh xong (spAPI_TkbChayNhanh), goi lai duoc nhieu lan.
    SET NOCOUNT ON;
    UPDATE k SET k.MaPhong = p.MaPhong
    FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_PhongLopMon p ON p.MaLop = k.MaLop AND p.MaMon = k.MaMon AND p.Enable = 1
    WHERE k.RunID = @RunID AND k.MaPhong IS NULL;
    DECLARE @n INT = @@ROWCOUNT;

    -- 2026-10-09 (RunID 1525): nhom phong dung chung (vd TA1/TA2 khoi 1) xep qua NHIEU buoc — solver dam bao so lop
    -- moi tiet <= so phong (khoa slot khi du phong) nhung buoc sau khong biet phong NAO da co lop -> 2 lop cung nhan
    -- TA2. Gan lai nhan: o tiet co 2 lop trung 1 phong trong nhom, chuyen lop thu 2 sang phong con trong cua nhom.
    DECLARE @Nhom TABLE (Nhom VARCHAR(10), MaPhong VARCHAR(20));
    INSERT @Nhom VALUES ('TA','TA1'), ('TA','TA2'), ('AN','AN1'), ('AN','AN2'), ('AN','AN3'),
        ('BOI','BOI1'), ('BOI','BOI2'), ('BOI','BOI3'), ('TV','TV1'), ('TV','TV2'), ('TN','LI'), ('TN','HOA'), ('TN','SINH');
    ;WITH R AS (
        SELECT k.ID, n.Nhom, k.Thu, k.Buoi, k.Tiet, k.MaPhong,
               ROW_NUMBER() OVER (PARTITION BY n.Nhom, k.Thu, k.Buoi, k.Tiet, k.MaPhong ORDER BY k.MaLop) AS rnPhong
        FROM tblTKB_KetQuaXep k INNER JOIN @Nhom n ON n.MaPhong = k.MaPhong
        WHERE k.RunID = @RunID AND k.MaLop <> 'HOP'
    ), Dup AS (
        SELECT ID, Nhom, Thu, Buoi, Tiet, ROW_NUMBER() OVER (PARTITION BY Nhom, Thu, Buoi, Tiet ORDER BY ID) AS stt
        FROM R WHERE rnPhong > 1
    ), Trong AS (
        SELECT d.Nhom, d.Thu, d.Buoi, d.Tiet, n.MaPhong,
               ROW_NUMBER() OVER (PARTITION BY d.Nhom, d.Thu, d.Buoi, d.Tiet ORDER BY n.MaPhong) AS stt
        FROM (SELECT DISTINCT Nhom, Thu, Buoi, Tiet FROM Dup) d
        INNER JOIN @Nhom n ON n.Nhom = d.Nhom
        WHERE NOT EXISTS (SELECT 1 FROM R WHERE R.Nhom = d.Nhom AND R.Thu = d.Thu AND R.Buoi = d.Buoi AND R.Tiet = d.Tiet AND R.MaPhong = n.MaPhong)
    )
    UPDATE k SET k.MaPhong = t.MaPhong
    FROM tblTKB_KetQuaXep k
    INNER JOIN Dup d ON d.ID = k.ID
    INNER JOIN Trong t ON t.Nhom = d.Nhom AND t.Thu = d.Thu AND t.Buoi = d.Buoi AND t.Tiet = d.Tiet AND t.stt = d.stt;
    SELECT @n AS SoTietGanPhong, @@ROWCOUNT AS SoTietDoiPhongTrung;
END