CREATE PROCEDURE spAPI_TkbKhoaPhongDungChungApDung
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Ap dung toan bo quy tac trong danh muc tblTKB_KhoaPhongDungChung (R1.2/1.3/1.6 — khoa toan bo
    -- 1 khung gio cho 1 nhom phong) vao phien TKB dang xay: chen 1 dong "chiem cho" (GV/Mon gia
    -- KHOAPHONG) cho tung phong khop LoaiKhoa, tung Tiet trong [TietTu..TietDen]. Nho vay Buoc 6
    -- (Auto) chi can doc lai chinh tblTKB_KetQuaXep de biet phong nao dang bi khoa, khong can bang
    -- cau hinh rieng nua — dung R17.
    --
    -- Cung 1 nhan "Tiet" ung voi gio hoc thuc te KHAC NHAU giua Tieu hoc va THCS-THPT (xem
    -- tblTKB_KhungGio), nen 1 quy tac co the co nhieu dong voi cung LoaiKhoa nhung khac MaCap
    -- (vd R1.6 co 3 dong: THCS_THPT Tiet3, TieuHoc Tiet3, TieuHoc Tiet4 — cung 1 khung gio thuc
    -- 9h30-10h05 nhung quy doi ra Tiet khac nhau theo cap). Phai loc dung MaCap cua RunID dang xay,
    -- neu khong se chen nham Tiet cua cap khac vao TKB cap nay.
    DECLARE @Cap VARCHAR(20) = NULL;
    DECLARE @KhoiRun VARCHAR(50);
    SELECT @KhoiRun = LEFT(Khoi, 2) FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    IF ISNUMERIC(@KhoiRun) = 1
    BEGIN
        DECLARE @KhoiSo INT = TRY_CAST(@KhoiRun AS INT);
        IF @KhoiSo BETWEEN 1 AND 5 SET @Cap = 'TieuHoc';
        ELSE IF @KhoiSo BETWEEN 6 AND 12 SET @Cap = 'THCS_THPT';
    END
    -- @Cap = NULL (Khoi rong, "1+" nhieu khoi khac cap, hoac khong parse duoc) => ap dung moi MaCap,
    -- giu hanh vi an toan nhu truoc khi co cot MaCap.

    DECLARE @SoLuongChen INT = 0;

    ;WITH PhongKhop AS (
        SELECT k.ID AS KhoaID, k.TenKhoa, k.Thu, k.Buoi, k.TietTu, k.TietDen, p.MaPhong
        FROM tblTKB_KhoaPhongDungChung k
        INNER JOIN tblTKB_PhongHoc p ON p.MaPhong LIKE k.LoaiKhoa + '%' AND p.Enable = 1
        WHERE k.Enable = 1
          AND (@Cap IS NULL OR k.MaCap IS NULL OR k.MaCap = @Cap)
    ),
    Tiets AS (
        SELECT pk.*, t.Tiet
        FROM PhongKhop pk
        CROSS APPLY (
            SELECT TOP (100) TietTu + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS Tiet
            FROM sys.all_objects
        ) t
        WHERE t.Tiet <= pk.TietDen
    )
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
    SELECT @RunID, LEFT(t.MaPhong, 3), t.Thu, t.Buoi, t.Tiet, 'KHOAPHONG', 'KHOAPHONG', t.MaPhong
    FROM Tiets t
    WHERE NOT EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep e
        WHERE e.RunID = @RunID AND e.Thu = t.Thu AND e.Buoi = t.Buoi AND e.Tiet = t.Tiet AND e.MaPhong = t.MaPhong
    );

    SET @SoLuongChen = @@ROWCOUNT;
    SELECT CAST(1 AS BIT) AS Success, @SoLuongChen AS SoLuongChen, N'Đã áp dụng quy tắc khóa phòng vào phiên' AS Message;
END