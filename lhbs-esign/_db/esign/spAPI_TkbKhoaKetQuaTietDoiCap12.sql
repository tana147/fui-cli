CREATE PROCEDURE spAPI_TkbKhoaKetQuaTietDoiCap12
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_6_Khoa ->
    -- spAPI_TkbKhoaKetQuaTietDoiCap12 (ten mo ta CHUC NANG thay vi so Round, vi SP nay la buoc KHOA
    -- dung chung SAU CA Round 5 (cap 2) LAN Round 6 (cap 1), khong gan voi 1 round rieng). Khong doi
    -- logic. MO TA NGAN: khoa cung ket qua tiet doi khoi 1-9 vua giai xong o Round 5/Round 6 (giong y
    -- het co che khoa cua Round 2 cho khoi 10-12) — dam bao Round 7/8 sau nay KHONG BAO GIO dung
    -- toi (LopDaKhoa trong solver tu bao ve, tblTKB_KetQuaXep_Khoa la nguon "da khoa" ma
    -- spAPI_TkbChayAuto/Round8 deu tu tru ra khi xoa/tinh NhuCau).
    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
    SELECT k.ID FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
    WHERE k.RunID = @RunID AND l.Khoi IN ('01','02','03','04','05','06','07','08','09') AND kh.KetQuaXepID IS NULL;

    SELECT @@ROWCOUNT AS SoTietDaKhoa;
END
