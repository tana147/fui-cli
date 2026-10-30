CREATE PROCEDURE spAPI_TkbTheoTuan_LichLop
    @Tuan       INT,
    @MaLop      VARCHAR(15),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Lich cua 1 Lop theo TUAN (2026-09-04, phuc vu dialog Ngay nghi pham vi LOP — hien thi luoi de
    -- bam chon slot) — Lop chi thuoc 1 khoi nen chi co dung 1 RunID kha thi gan nhat lien quan.
    DECLARE @RunID INT = (
        SELECT MAX(c.RunID)
        FROM tblTKB_ChayAutoLog c
        JOIN tblTKB_Lop l ON l.Khoi = c.Khoi AND l.MaLop = @MaLop AND l.Enable = 1
        WHERE c.TuanHienTai = @Tuan AND c.KhaThi = 1 AND c.Enable = 1
    );

    SELECT k.ID, k.RunID, k.MaLop, k.MaMon, m.TenMon, k.MaGV, gv.HoTen AS TenGV, k.Thu, k.Buoi, k.Tiet
    FROM tblTKB_KetQuaXep k
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = k.MaMon
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
    WHERE k.RunID = @RunID AND k.MaLop = @MaLop
    ORDER BY k.Thu, k.Buoi, k.Tiet;
END
