CREATE PROCEDURE spAPI_TkbChuaXepKhaThi
    @RunID INT,
    @MaLop VARCHAR(10),
    @Thu INT,
    @Buoi VARCHAR(10),
    @Tiet INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Danh sach "chua xep duoc" CUA RIENG LOP nay, loc con nhung dong ma GV phu trach dang RANH
    -- dung khung gio (@Thu/@Buoi/@Tiet) — dung cho modal "+" tren o trong cua luoi (2026-08-30).
    -- MaLop coi nhu da ranh (day la 1 o trong tren chinh luoi cua lop do) nen chi can check GV.
    SELECT cxd.MaLop, cxd.MaMon, m.TenMon, cxd.MaGV, gv.HoTen AS TenGV, cxd.SoTiet
    FROM tblTKB_ChayAutoKhongXepDuoc cxd
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = cxd.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = cxd.MaGV
    WHERE cxd.RunID = @RunID AND cxd.MaLop = @MaLop
      AND NOT EXISTS (
        SELECT 1 FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.MaGV = cxd.MaGV AND k.Thu = @Thu AND k.Buoi = @Buoi AND k.Tiet = @Tiet
      )
    ORDER BY m.TenMon;
END
