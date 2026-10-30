CREATE PROCEDURE spAPI_TkbCapMonDongBoKiemTra
    @RunID INT
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-11: chuan hoa lai truy van kiem tra dong bo cap mon (R24, bang tblTKB_CapMonDongBoGio)
    -- ma Claude van chay tay nhieu lan trong phien lam viec — CP-SAT (R24 trong TkbCpSatSolver.cs)
    -- chi dam bao dong bo o LAN GIAI TU DONG; sau khi sua tay tung tiet bang UI (khong qua solver)
    -- rat de vo tinh pha dong bo (da gap it nhat 3 lan trong phien 2026-09-11) — chay SP nay sau moi
    -- lan sua tay 1 ben cua 1 cap R24 de phat hien ngay, dung doi den luc kiem tra tong the moi thay.

    ;WITH ThatSuA AS (
        SELECT c.ID AS CapID, c.MaLopA, c.MaMonA, c.MaLopB, c.MaMonB, k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_CapMonDongBoGio c
        INNER JOIN tblTKB_KetQuaXep k ON k.MaLop = c.MaLopA AND k.MaMon = c.MaMonA AND k.RunID = @RunID
        WHERE c.Enable = 1
    ),
    ThatSuB AS (
        SELECT c.ID AS CapID, c.MaLopA, c.MaMonA, c.MaLopB, c.MaMonB, k.Thu, k.Buoi, k.Tiet
        FROM tblTKB_CapMonDongBoGio c
        INNER JOIN tblTKB_KetQuaXep k ON k.MaLop = c.MaLopB AND k.MaMon = c.MaMonB AND k.RunID = @RunID
        WHERE c.Enable = 1
    )
    SELECT CapID, MaLopA, MaMonA, MaLopB, MaMonB, Thu, Buoi, Tiet, N'ThieuBenB' AS LoaiLoi
    FROM ThatSuA a
    WHERE NOT EXISTS (SELECT 1 FROM ThatSuB b WHERE b.CapID = a.CapID AND b.Thu = a.Thu AND b.Buoi = a.Buoi AND b.Tiet = a.Tiet)
    UNION ALL
    SELECT CapID, MaLopA, MaMonA, MaLopB, MaMonB, Thu, Buoi, Tiet, N'ThieuBenA' AS LoaiLoi
    FROM ThatSuB b
    WHERE NOT EXISTS (SELECT 1 FROM ThatSuA a WHERE a.CapID = b.CapID AND a.Thu = b.Thu AND a.Buoi = b.Buoi AND a.Tiet = b.Tiet)
    ORDER BY CapID, Thu, Buoi, Tiet;
END
