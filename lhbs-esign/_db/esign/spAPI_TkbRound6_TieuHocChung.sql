CREATE PROCEDURE spAPI_TkbRound6_TieuHocChung
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 420,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN (2026-09-24): Round 6 MOI — giai CHUNG toan bo tieu hoc (khoi 01-05, 35 lop) trong 1 job
    -- CP-SAT thay vi tung GV/tung lop tuan tu. Ly do: doi chung voi lich that tuan 8 cho thay nguoi xep
    -- tay xep MA TRAN GV CHUYEN truoc (o GVCN hop khoi bat buoc la mon chuyen), GVCN dien sau; giai tuan tu
    -- khong nhin thay cau truc nay nen ket ~30 tiet (TOAN/HDTN1). Giai chung: tat ca lop + GV chuyen cung
    -- 1 mo hinh nen o GVCN hop khoi tu dong roi vao mon chuyen. Hop khoi tieu hoc = cung (co Cung trong
    -- GVBanCoDinh), hop to (TD-AN-MT, TA, khoi truong) = mem — dung cach nguoi xep tay lam.
    -- Khong khoa cung ket qua (khac Round 2): de Round 7/9 con sua phan con thieu; Round 8 chi con khoi 06-09.
    -- Poll bang /TkbChayAutoTrangThai giong Round 2 (job bat dong bo, tra 'DangChay').
    EXEC spAPI_TkbChayAuto
        @Khoi = '01,02,03,04,05',
        @HocKy = @HocKy,
        @MaxSecs = @MaxSecs,
        @TuanHienTai = @TuanHienTai,
        @RunIDDangXay = @RunID,
        @KhongChoSkip = 0,
        @sys_UserID = @sys_UserID;
END
