CREATE PROCEDURE spAPI_TkbNhanBanRunID
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-30 (theo de xuat nguoi dung "toi tot thoi gian chay" — thu nghiem thay doi Round 9/10/tham so ma khong phai
    -- chay lai tu Round 1, von ton 45-90 phut). Nhan ban TOAN BO tblTKB_KetQuaXep + tblTKB_KetQuaXep_Khoa cua 1 RunID
    -- sang 1 RunID moi (Enable=1, cung TuanHienTai/HocKy), giu nguyen trang thai khoa. RunID moi dung duoc ngay voi
    -- spAPI_TkbRound9_SuaOCuoi / spAPI_TkbRound10_HoanDoi / spAPI_TkbDanhGiaRun nhu 1 RunID chay that, khong anh huong RunID goc.
    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunIDGoc, NULL AS RunIDMoi, N'KhongTonTai' AS TrangThai;
        RETURN;
    END

    DECLARE @HocKy VARCHAR(4), @TuanHienTai INT, @Khoi NVARCHAR(50);
    SELECT @TuanHienTai = TuanHienTai, @Khoi = Khoi FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    SET @HocKy = 'HK1';

    DECLARE @RunIDMoi INT;
    INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
    VALUES (SYSUTCDATETIME(), @Khoi, 0, N'Optimal', @sys_UserID, @TuanHienTai, 1);
    SET @RunIDMoi = SCOPE_IDENTITY();

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT @RunIDMoi, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro
    FROM tblTKB_KetQuaXep WHERE RunID = @RunID;

    -- Khoa lai dung cac dong da khoa o ban goc (khop theo lop/thu/buoi/tiet/mon, vi ID se khac).
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
    SELECT n.ID FROM tblTKB_KetQuaXep o
    INNER JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = o.ID
    INNER JOIN tblTKB_KetQuaXep n ON n.RunID = @RunIDMoi AND n.MaLop = o.MaLop AND n.Thu = o.Thu AND n.Buoi = o.Buoi
         AND n.Tiet = o.Tiet AND n.MaMon = o.MaMon AND ISNULL(n.MaGV,'') = ISNULL(o.MaGV,'')
    WHERE o.RunID = @RunID
    GROUP BY n.ID;

    -- Sao chep moc danh gia da co (de xem lich su tien trinh lien tuc tren nhanh moi).
    INSERT INTO tblTKB_DanhGiaRound (RunID, Moc, Khoi, TongCan, DaXep)
    SELECT @RunIDMoi, Moc, Khoi, TongCan, DaXep FROM tblTKB_DanhGiaRound WHERE RunID = @RunID;

    SELECT @RunID AS RunIDGoc, @RunIDMoi AS RunIDMoi, N'HoanTat' AS TrangThai,
           (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunIDMoi) AS SoTiet;
END
