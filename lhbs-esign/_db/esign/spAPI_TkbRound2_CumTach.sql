CREATE PROCEDURE spAPI_TkbRound2_CumTach
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 600,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_5a_CumTach
    -- -> spAPI_TkbRound2_CumTach. Khong doi logic.
    -- MO TA NGAN: Round 2 — giai CUM TACH (nhom nang luc AV/Tin, phan ban chuyen de) + cap mon dong
    -- bo (R23/R24) cho khoi 10-12, KHONG dung solver cho lop thuong. Chay SAU Round 1, TRUOC Round 3/4
    -- — day la nhom rang buoc dong bo chat nhat nen giai truoc tien khi ban co con trong nhat.
    -- 2026-09-15 (theo de xuat nguoi dung, tach Round 1.5 thanh 1.5a/1.5b): Round 1.5a chi giai CUM
    -- TACH AV/chuyen de + Cap mon dong bo (R23/R24) cho khoi 10-12 (@ChiCumTach=1, ~81/362 dong PCGD
    -- thuc te) — giai TRUOC phan lop thuong (1.5b) trong khi ban co con trong nhat, giam khong gian
    -- tim kiem cho dung nhom rang buoc dong bo chat nhat, thay vi giai gop chung ca 362 dong 1 lan
    -- nhu spAPI_TkbRound1_5_GiaiCumTach cu (van giu nguyen, khong xoa, de tuong thich nguoc).
    EXEC spAPI_TkbChayAuto
        @Khoi = '10,11,12',
        @HocKy = @HocKy,
        @MaxSecs = @MaxSecs,
        @TuanHienTai = @TuanHienTai,
        @RunIDDangXay = @RunID,
        @ChiCumTach = 1,
        @KhongChoSkip = 0,
        @sys_UserID = @sys_UserID;
END
