CREATE PROCEDURE spAPI_TkbPhienDangXayList
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Danh sach "phien TKB dang xay" (R17) — RunID da tao qua spAPI_TkbPhienMoi, dang duoc
    -- khoa tay dan (Buoc 1-5), CHUA chay Auto. Khac spAPI_TkbKetQuaXepRunListKhaThi (loc KhaThi=1,
    -- tuc la RunID DA giai xong bang solver).
    SELECT l.RunID, l.Khoi, l.LoiChiTiet AS GhiChu, l.ThoiGianBatDau,
        (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = l.RunID) AS SoDongDaKhoa
    FROM tblTKB_ChayAutoLog l
    WHERE l.TrangThai = N'DangXay' AND l.Enable = 1
    ORDER BY l.RunID DESC;
END