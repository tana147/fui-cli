CREATE PROCEDURE spAPI_TkbRound4_LopThuongCap3
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 900,
    @MaxSecsPerLop INT = 60,
    @SoLopMoiLan INT = 10,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (thiet ke moi, xem spAPI_TkbGiaiLopThuongTuanTu de biet ly do day du — doi chung
    -- RunID 1311 phat hien 63% phan du la mon TOAN rai deu tren 28 GV, khong tap trung vao GV nao —
    -- chung to canh tranh xay ra o LOP, khong phai GV): chuyen sang goi engine giai TUNG LOP mot.
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_5b_LopThuong
    -- -> spAPI_TkbRound4_LopThuongCap3. Khong doi logic.
    -- MO TA NGAN: Round 4 — giai TOAN BO mon THUONG (tiet don: Toan/Van/Su/Ly thuong...) con lai cua
    -- khoi 10-12, sau khi Round 2 (cum tach) va Round 3 (tiet doi) da khoa xong. Chay CUOI CUNG trong
    -- nhom khoi 10-12 — luc nay chi con lap day cac slot don le, khong con rang buoc dong bo can giu cho.
    -- 2026-09-15 (theo de xuat nguoi dung, tach Round 1.5 thanh 1.5a/1.5b): giai PHAN LOP
    -- THUONG con lai cua khoi 10-12 (@ChiCumTach=2 — loai het cum tach, ~281/362 dong PCGD thuc te),
    -- CHAY SAU khi Round 2 da khoa cung cum tach — luc nay CP-SAT chi can lap day 570 tiet Toan/Van/Ly...
    -- vao slot con trong, khong con phai canh tranh khong gian tim kiem voi rang buoc dong bo R23/R24
    -- (da giai xong o Round 2). @RunID phai la RunID DA chay Round 2 (dung @RunIDDangXay de noi tiep).
    EXEC spAPI_TkbGiaiLopThuongTuanTu
        @Khoi = '10,11,12',
        @HocKy = @HocKy,
        @TuanHienTai = @TuanHienTai,
        @MaxSecsPerLop = @MaxSecsPerLop,
        @SoLopMoiLan = @SoLopMoiLan,
        @RunID = @RunID,
        @sys_UserID = @sys_UserID;
END
