CREATE PROCEDURE spAPI_TkbKhoaKetQuaKhoi1012
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_5_Khoa ->
    -- spAPI_TkbKhoaKetQuaKhoi1012 (doi thanh ten mo ta CHUC NANG thay vi so Round, vi SP nay la buoc
    -- KHOA dung chung SAU CA Round 2 (cum tach) LAN Round 3 (tiet doi), khong gan voi 1 round rieng).
    -- Khong doi logic. MO TA NGAN: khoa cung TOAN BO ket qua khoi 10-12 vua giai xong o Round 2/Round 3
    -- (giong y het co che khoa cua Round 1 cho SH/HDTN1) — dam bao Round 7/8 sau nay KHONG BAO GIO dung
    -- toi (LopDaKhoa trong solver da tu bao ve, va tblTKB_KetQuaXep_Khoa la nguon "da khoa" ma
    -- spAPI_TkbChayAuto/Round8 deu tu tru ra khi xoa/tinh NhuCau).
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
    SELECT k.ID FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
    WHERE k.RunID = @RunID AND l.Khoi IN ('10', '11', '12') AND kh.KetQuaXepID IS NULL;

    SELECT @@ROWCOUNT AS SoTietDaKhoa;
END
