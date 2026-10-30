CREATE PROCEDURE spAPI_TkbRound6_TietDoiCap1
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 400,
    @MaxSecsPerGV INT = 90,
    @SoGVMoiLan INT = 5,
    @XepToanTruoc BIT = 1,
    @SoLopToan INT = 40,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (thiet ke moi, xem spAPI_TkbGiaiTietDoiTuanTu): chuyen sang goi engine giai TUNG
    -- GV mot thay vi giai gop.
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_6b_TietDoiCap1
    -- -> spAPI_TkbRound6_TietDoiCap1. Khong doi logic.
    -- MO TA NGAN: Round 6 — giai TIET DOI cap 1 (khoi 01-05): chu yeu TV theo pattern rieng tung
    -- khoi + AI/Boi/Nhac. Chay SAU Round 5 (cap 2 da xong) — round CUOI CUNG cua nhom tiet doi truoc
    -- khi sang Round 7.
    -- 2026-09-16: chay SAU Round 5 — chu yeu la TV theo pattern rieng tung khoi
    -- + AI/BOI/NHAC. Xem giai thich chung o spAPI_TkbRound5_TietDoiCap2.
    -- SUA 2026-09-19 (buoc A, xac nhan sau doi chieu lich that): TOAN tieu hoc truoc day bi xep o Round 7/8
    -- nhu "o thua cuoi cung" (21 tiet o Chieu tiet 4, thieu 23 tiet), trong khi nguoi xep tay dat mon
    -- chinh vao gio dep truoc. Khi het GV tiet doi (HoanTat), xep TOAN tung lop tieu hoc ngay (mon chinh
    -- chiem gio truoc mon phu), ket hop quy tac mem PhatKhungGio. Tat bang @XepToanTruoc = 0.
    DECLARE @TrangThaiDoi VARCHAR(12);
    EXEC spAPI_TkbGiaiTietDoiTuanTu
        @Khoi = '01,02,03,04,05',
        @HocKy = @HocKy,
        @TuanHienTai = @TuanHienTai,
        @MaxSecsPerGV = @MaxSecsPerGV,
        @SoGVMoiLan = @SoGVMoiLan,
        @RunID = @RunID,
        @sys_UserID = @sys_UserID,
        @TrangThaiRa = @TrangThaiDoi OUTPUT;

    IF @XepToanTruoc = 1 AND @TrangThaiDoi = 'HoanTat'
        EXEC spAPI_TkbGiaiLopThuongTuanTu
            @Khoi = '01,02,03,04,05',
            @HocKy = @HocKy,
            @TuanHienTai = @TuanHienTai,
            @MaxSecsPerLop = 60,
            @SoLopMoiLan = @SoLopToan,
            @Nhom = 'MC',
            @ChiMon = 'TOAN',
            @RunID = @RunID,
            @sys_UserID = @sys_UserID;
END
