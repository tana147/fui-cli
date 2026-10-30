CREATE PROCEDURE spAPI_TkbCumTachSlotByLop
    @RunID INT,
    @MaLop VARCHAR(10),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Lop nay (lop nguon) dang "nhuong" hoc sinh cho nhom con tai nhung slot nao (2026-09-02) — dung
    -- de UI luoi lop goc hien thi "Hoc nhom" thay vi "+" (trong) — KHONG dong bo vao tblTKB_KetQuaXep,
    -- chi la overlay hien thi phia client, xem uc-tkb-grid.vue prop groupSlots.
    SELECT DISTINCT k.Thu, k.Buoi, k.Tiet, ct.MaCumTach, ct.TenCum
    FROM tblTKB_CumTach_LopNguon ln
    INNER JOIN tblTKB_CumTach ct ON ct.ID = ln.CumTachID AND ct.Enable = 1
    INNER JOIN tblTKB_CumTach_NhomCon nc ON nc.CumTachID = ct.ID
    INNER JOIN tblTKB_KetQuaXep k ON k.RunID = @RunID AND k.MaLop = nc.MaLop
    WHERE ln.MaLop = @MaLop;
END
