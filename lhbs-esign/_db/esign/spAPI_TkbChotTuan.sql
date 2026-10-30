CREATE PROCEDURE spAPI_TkbChotTuan
    @RunID INT,
    @sys_UserID NVARCHAR(50)
AS
BEGIN
    -- 2026-10-09: "Chot tuan" — danh dau lan chay @RunID la TKB chinh thuc cua tuan no xep (tblTKB_TuanChot, moi tuan 1 dong,
    -- chot lai thi ghi de) va ghi o cua cac mon co MonQuyTac 'NeoTuanTruoc' (vd SHTV) vao tblTKB_NeoO. Lan xep tuan sau,
    -- spAPI_TkbChayAuto lay o tuan gan nhat lam o neo (nguoi xep tay giu nguyen o SHTV qua tuan — doi chieu TKB that tuan 8-11).
    SET NOCOUNT ON;
    DECLARE @Tuan INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    IF @Tuan IS NULL
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Không tìm thấy lần chạy ' + CAST(@RunID AS NVARCHAR(20)) + N' hoặc lần chạy chưa gắn tuần' AS Message;
        RETURN;
    END

    BEGIN TRAN;
    DELETE FROM tblTKB_TuanChot WHERE Tuan = @Tuan;
    INSERT INTO tblTKB_TuanChot (Tuan, RunID, NguoiChot, ThoiGian) VALUES (@Tuan, @RunID, @sys_UserID, SYSDATETIME());

    DELETE n FROM tblTKB_NeoO n
    WHERE n.Tuan = @Tuan
      AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac q WHERE q.MaMon = n.MaMon AND q.LoaiQuyTac = 'NeoTuanTruoc' AND q.Enable = 1);
    INSERT INTO tblTKB_NeoO (Tuan, MaLop, MaMon, Thu, Buoi, Tiet, Nguon)
    SELECT DISTINCT @Tuan, k.MaLop, k.MaMon, k.Thu, k.Buoi, k.Tiet, N'Chốt RunID ' + CAST(@RunID AS NVARCHAR(20))
    FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID AND k.MaLop <> 'HOP' AND k.MaLop NOT LIKE '26%'
      AND EXISTS (SELECT 1 FROM tblTKB_MonQuyTac q WHERE q.MaMon = k.MaMon AND q.LoaiQuyTac = 'NeoTuanTruoc' AND q.Enable = 1
                  AND (q.Khoi IS NULL OR q.Khoi = LEFT(k.MaLop, 2)));
    DECLARE @SoO INT = @@ROWCOUNT;
    COMMIT;

    SELECT CAST(1 AS BIT) AS Success,
           N'Đã chốt RunID ' + CAST(@RunID AS NVARCHAR(20)) + N' cho tuần ' + CAST(@Tuan AS NVARCHAR(10))
           + N'. Lưu ' + CAST(@SoO AS NVARCHAR(10)) + N' ô (mọi môn) làm ô neo để tuần ' + CAST(@Tuan + 1 AS NVARCHAR(10)) + N' giữ nguyên giờ, chỉ đổi phần bị ảnh hưởng.' AS Message;
END
