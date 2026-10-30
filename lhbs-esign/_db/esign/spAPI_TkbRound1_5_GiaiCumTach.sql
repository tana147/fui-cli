CREATE PROCEDURE spAPI_TkbRound1_5_GiaiCumTach
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 1500,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-12 (REVERT KhongChoSkip): da test that — cam skip hoan toan cho ca khoi 10-12 khien
    -- CP-SAT bao Infeasible NGAY (vai phut, khong phai het 1500s) — dieu tra sau cho thay nguyen nhan
    -- LA 1 vai xung dot lich CU THE (vd 1 GV day tieng Anh xuyen ca khoi 11 lan 12, bi ep 2 khung gio
    -- dong bo khac nhau + hop to co dinh, khong con ngay nao trong), KHONG PHAI toan bo bai toan vo
    -- nghia — da CHUNG MINH bang RunID 1260 (cho phep skip) van xep duoc >90% (chi 30/284 don vi that
    -- bai). Cam tuyet doi lam MAT SACH ket qua (0 tiet) chi vi 1 vai xung dot cuc bo — danh doi khong
    -- dang. Quay lai cho phep skip (KhongChoSkip=0, mac dinh). Gia tri thuc su cua tinh nang nay: dung
    -- @KhongChoSkip=1 THU CONG cho 1 pham vi HEP (vd 1 GV/1 vai lop cu the) khi da xac dinh dung nguyen
    -- nhan, KHONG dung dien rong cho ca khoi.
    -- 2026-09-12 (theo de xuat nguoi dung, co du lieu that chung minh): giai RIENG khoi 10-12 (Cum
    -- tach AV R23 + Cap mon dong bo R24 + rule 7j gioi han 2 tiet TA/ngay — nhom rang buoc CHAT NHAT
    -- toan truong) NGAY SAU Round 1, TRUOC Round 2 — dung nguyen ly xep lich chuan "giai phan rang
    -- buoc chat nhat truoc khi ban co con trong nhat", thay vi de den Round 4 (cuoi cung, luc hau het
    -- slot da bi Round 2 chiem). Xac nhan qua du lieu that: 36 GV day CA cum tach LAN lop thuong (vd
    -- 1 GV co 145 dong lop thuong nhung chi 7 dong cum tach) hien dang bi loai KHOI Round 2 HOAN TOAN
    -- (ca 145 dong lop thuong cung bi don sang Round 4 oan, khong lien quan gi cum tach) — giai xong o
    -- day roi khoa cung se giup Round 2 (sua dieu kien loai tru rieng, xem spAPI_TkbXepDoKhanHiem) tu
    -- nhan lai 36 GV nay cho phan lop thuong cua ho, giam tai dang ke cho Round 4.
    EXEC spAPI_TkbChayAuto
        @Khoi = '10,11,12',
        @HocKy = @HocKy,
        @MaxSecs = @MaxSecs,
        @TuanHienTai = @TuanHienTai,
        @RunIDDangXay = @RunID,
        @KhongChoSkip = 0,
        @sys_UserID = @sys_UserID;
END
