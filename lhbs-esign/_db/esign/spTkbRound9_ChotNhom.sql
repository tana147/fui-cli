CREATE PROCEDURE spTkbRound9_ChotNhom
    @RunID INT,
    @MaxChoGiay INT = 240,
    @CaiThien INT OUTPUT,
    @TietThem INT OUTPUT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-25: CHOT nhom Round 9 dang do dang (noi bo, khong phai API). Truoc day ban chup nhom nam trong bang tam
    -- (#Snap) — neu phien SQL bi cat giua chung (dong tab UI, timeout, restart) thi cac dong 'movable' da bi xoa va
    -- ban chup mat luon, nhom khong duoc khoi phuc (RunID 1345 mat ~54 tiet). Nay ban chup luu ben trong
    -- tblTKB_Round9Snap + tblTKB_Round9Pending; SP nay duoc goi (1) ngay sau khi giai nhom, (2) dau moi lan goi
    -- spAPI_TkbRound9_SuaOCuoi de chot nhom bi bo do: cho solver xong, so voi ban chup, giu neu nhieu tiet hon,
    -- neu khong thi khoi phuc tu ban chup.
    SET @CaiThien = 0; SET @TietThem = 0;
    DECLARE @L VARCHAR(10), @LopStr VARCHAR(100), @MaxID INT, @SoTruoc INT, @TrangThai NVARCHAR(50), @Waited INT = 0, @SoSau INT;
    SELECT @L = L, @LopStr = NhomLop, @MaxID = MaxIDTruoc, @SoTruoc = SoTruoc FROM tblTKB_Round9Pending WHERE RunID = @RunID;
    IF @L IS NULL RETURN;

    SELECT @TrangThai = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    WHILE @TrangThai = N'DangChay' AND @Waited < @MaxChoGiay
    BEGIN
        WAITFOR DELAY '00:00:01';
        SET @Waited = @Waited + 1;
        EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
        SELECT @TrangThai = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    END

    DECLARE @Nhom TABLE (MaLop VARCHAR(10) PRIMARY KEY);
    IF @LopStr = '*' INSERT INTO @Nhom (MaLop) SELECT DISTINCT k.MaLop FROM tblTKB_KetQuaXep k INNER JOIN tblTKB_Lop lz ON lz.MaLop = k.MaLop WHERE k.RunID = @RunID;
    ELSE INSERT INTO @Nhom (MaLop) SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@LopStr, ',');

    SELECT @SoSau = COUNT(*) FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID AND k.MaLop IN (SELECT MaLop FROM @Nhom) AND k.MaMon <> 'KHOAPHONG';

    IF @SoSau > @SoTruoc
    BEGIN
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT k.ID FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaLop IN (SELECT MaLop FROM @Nhom) AND kh.KetQuaXepID IS NULL;
        SET @CaiThien = 1; SET @TietThem = @SoSau - @SoTruoc;
        INSERT INTO tblTKB_Round9DaXuLy (RunID, MaLop, KetQua, SoTietTruoc, SoTietSau, NhomLop, ThoiGian)
        VALUES (@RunID, @L, 'CaiThien', @SoTruoc, @SoSau, @LopStr, SYSUTCDATETIME());
    END
    ELSE
    BEGIN
        DELETE kh FROM tblTKB_KetQuaXep_Khoa kh INNER JOIN tblTKB_KetQuaXep k ON k.ID = kh.KetQuaXepID
        WHERE k.RunID = @RunID AND k.ID > @MaxID AND k.MaLop IN (SELECT MaLop FROM @Nhom);
        DELETE k FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.ID > @MaxID AND k.MaLop IN (SELECT MaLop FROM @Nhom);
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
        SELECT @RunID, s.MaLop, s.Thu, s.Buoi, s.Tiet, s.MaMon, s.MaGV, s.MaPhong, s.XoayTro
        FROM tblTKB_Round9Snap s WHERE s.RunID = @RunID AND s.Movable = 1;
        -- DISTINCT: ban chup co the co >1 dong cung o (lop,thu,buoi,tiet) -> join lap k.ID -> trung khoa chinh, ca lenh INSERT that bai va cac dong khoi phuc mat khoa (RunID 1384).
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT DISTINCT k.ID FROM tblTKB_KetQuaXep k
        INNER JOIN tblTKB_Round9Snap s ON s.RunID = @RunID AND s.MaLop = k.MaLop AND s.Thu = k.Thu AND s.Buoi = k.Buoi AND s.Tiet = k.Tiet
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND s.Movable = 1 AND s.DaKhoa = 1 AND kh.KetQuaXepID IS NULL;
        INSERT INTO tblTKB_Round9DaXuLy (RunID, MaLop, KetQua, SoTietTruoc, SoTietSau, NhomLop, ThoiGian)
        VALUES (@RunID, @L, 'KhoiPhuc', @SoTruoc, @SoSau, @LopStr, SYSUTCDATETIME());
    END

    DELETE FROM tblTKB_Round9Snap WHERE RunID = @RunID;
    DELETE FROM tblTKB_Round9Pending WHERE RunID = @RunID;
END
