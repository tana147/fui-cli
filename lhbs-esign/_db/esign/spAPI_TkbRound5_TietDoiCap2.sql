CREATE PROCEDURE spAPI_TkbRound5_TietDoiCap2
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 400,
    @MaxSecsPerGV INT = 90,
    @SoGVMoiLan INT = 5,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (thiet ke moi, xem spAPI_TkbGiaiTietDoiTuanTu de biet ly do day du — doi chung
    -- lich that tuan 8 phat hien 82% case "chua xep duoc" la do GV fan-out nhieu lop bi "chim" giua
    -- dam dong khi giai gop, khong phai do het cho): chuyen sang goi engine giai TUNG GV mot.
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_6a_TietDoiCap2
    -- -> spAPI_TkbRound5_TietDoiCap2. Khong doi logic.
    -- MO TA NGAN: Round 5 — giai TIET DOI (GDQP/STEM/ENG1/ENG2/TV pattern...) cap 2 (khoi 06-09).
    -- Chay SAU Round 4 (khoi 10-12 da xong het), TRUOC Round 6 — dung nguyen tac "cap cao truoc, cap
    -- thap sau" de GV day lien cap khong bi cap thap chiem gio truoc gio dung.
    -- 2026-09-16 (theo de xuat nguoi dung, tach Round 1.6 thanh 1.6a/1.6b theo cap hoc): kiem chung
    -- qua du lieu that tuan 8 — 0 GV nao day tiet doi o CA 2 cap cung luc, nen tach an toan tuyet doi
    -- (khong co rui ro thu tu xu ly sai lech nhu vu 10-12/Round 7). Loi ich thuan tuy la giam khong
    -- gian tim kiem (210 dong cap 2 rieng thay vi gop chung 374 dong ca 2 cap).
    -- Round 5 = CAP 2 (khoi 06-09) chay TRUOC — theo dung nguyen tac da chot "xep cap cao truoc, cap
    -- thap sau" (GV lien cap TD/Nhac/Boi/Tin day ca 1-12 se bi cap cao chiem gio truoc, dung thu tu).
    EXEC spAPI_TkbGiaiTietDoiTuanTu
        @Khoi = '06,07,08,09',
        @HocKy = @HocKy,
        @TuanHienTai = @TuanHienTai,
        @MaxSecsPerGV = @MaxSecsPerGV,
        @SoGVMoiLan = @SoGVMoiLan,
        @RunID = @RunID,
        @sys_UserID = @sys_UserID;
END
