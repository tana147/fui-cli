CREATE PROCEDURE spAPI_TkbDoiGVHangLoat
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(10),
    @MaGVMoi VARCHAR(15),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Doi GV cho TOAN BO tiet cua 1 (Lop,Mon) trong RunID, giu nguyen slot da xep — KHONG qua solver
    -- (2026-09-02). Validate GV moi khong trung lich o bat ky slot nao dang co cua (Lop,Mon) nay,
    -- so voi lich GV moi o cac lop/mon KHAC cung RunID.

    IF NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon)
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Môn này chưa có tiết nào được xếp trong lần chạy này' AS Message;
        RETURN;
    END

    DECLARE @TrungLop VARCHAR(10);
    SELECT TOP 1 @TrungLop = k2.MaLop
    FROM tblTKB_KetQuaXep k1
    INNER JOIN tblTKB_KetQuaXep k2
        ON k2.RunID = k1.RunID AND k2.Thu = k1.Thu AND k2.Buoi = k1.Buoi AND k2.Tiet = k1.Tiet
        AND k2.MaGV = @MaGVMoi
        AND NOT (k2.MaLop = k1.MaLop AND k2.MaMon = k1.MaMon)
    WHERE k1.RunID = @RunID AND k1.MaLop = @MaLop AND k1.MaMon = @MaMon;

    IF @TrungLop IS NOT NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Giáo viên mới đã có lịch khác trùng giờ (lớp ' + @TrungLop + N')' AS Message;
        RETURN;
    END

    UPDATE tblTKB_KetQuaXep SET MaGV = @MaGVMoi
    WHERE RunID = @RunID AND MaLop = @MaLop AND MaMon = @MaMon;

    SELECT CAST(1 AS BIT) AS Success, N'Đã đổi giáo viên cho toàn bộ tiết của môn này' AS Message;
END
