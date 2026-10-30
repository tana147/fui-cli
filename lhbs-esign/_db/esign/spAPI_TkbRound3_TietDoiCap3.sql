CREATE PROCEDURE spAPI_TkbRound3_TietDoiCap3
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecs INT = 400,
    @MaxSecsPerGV INT = 90,
    @SoGVMoiLan INT = 3,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8): doi ten tu spAPI_TkbRound1_5c_TietDoi
    -- -> spAPI_TkbRound3_TietDoiCap3. Khong doi logic.
    -- SUA 2026-09-18 (thiet ke moi sau khi doi chung lich that tuan 8 — xem spAPI_TkbGiaiTietDoiTuanTu
    -- de biet ly do day du): chuyen tu 1 EXEC gop @ChiMonDoi=1 cho ca khoi 10-12 (cach cu, de bi GV hep
    -- gio/fan-out nhieu lop "chim" giua dam dong) sang goi engine dung chung spAPI_TkbGiaiTietDoiTuanTu
    -- — giai TUNG GV mot theo do "cang" (SoCapCanXep/SoCapKhaDung), khoa ngay sau moi GV. @MaxSecs cu
    -- (danh cho 1 lan goi gop) khong con dung nua, giu lai tham so de tuong thich nguoc (khong dung
    -- toi); dung @MaxSecsPerGV/@SoGVMoiLan moi thay the.
    -- MO TA NGAN: Round 3 — xep TRUOC toan bo cac mon TIET DOI (GDQP/STEM/ENG1/ENG2...) cua khoi
    -- 10-12 KHONG thuoc cum tach (@ChiMonDoi=1, @ChiCumTach=2), chay SAU Round 2 (cum tach da khoa)
    -- va TRUOC Round 4 (lop thuong). Muc dich: danh cho tiet doi 2 slot LIEN KE trong khi lop con
    -- nhieu cho trong nhat, tranh bi cac mon tiet don (Toan/Van/Su...) o 1.5b xep vao lam vo cap lien
    -- ke can thiet (tiet don khong quan tam lien ke, tiet doi thi bat buoc — xep tiet don truoc de lai
    -- "vun" slot le, tiet doi khong con cho).
    --
    -- 2026-09-17 (theo de xuat nguoi dung, chung minh toan hoc + kiem chung du lieu that): Round 5/6
    -- da lam dung viec nay cho khoi 1-9 tu truoc (theo dung nguyen tac R18 "xep tiet doi khi ban
    -- co con trong nhat"), nhung khoi 10-12 truoc day KHONG co buoc tuong duong — tiet doi cua khoi
    -- 10-12 (vd GDQP 10F/12B) phai canh tranh truc tiep trong Round 4 (giai gop TAT CA mon thuong
    -- khoi 10-12 cung luc), dan toi bi "skip" du van con du SO LUONG slot trong (chi la khong LIEN KE
    -- nhau nua). Da kiem chung thuc te RunID 1295: 10F/GDQP va 12B/GDQP bi Round 4 bo sot, Round 7
    -- (giai rieng tung GV) cung khong cuu duoc (khong con cap lien ke nao de dung), chi Round 8 (duoc
    -- phep XOA VA XEP LAI) moi giai quyet duoc — Round 3 them vao de tranh phai cho den Round 8 moi
    -- sua, giam rui ro va thoi gian giai tong the.
    -- 2026-09-26: GV THINH GIANG / it o cho phep duoc xep TRUOC (moi khoi, moi mon), theo do khan hiem, khoa ngay — xem
    -- spAPI_TkbRound3b_ThinhGiang. Moi lan goi Round 3 xu ly toi @SoGVMoiLan GV thinh giang; con GV thi tra 'ConTiepTuc' (UI tu goi lai),
    -- het GV thi moi sang tiet doi khoi 10-12 nhu cu.
    DECLARE @TrangThaiTG VARCHAR(12), @SoConTG INT;
    EXEC spAPI_TkbRound3b_ThinhGiang
        @HocKy = @HocKy, @TuanHienTai = @TuanHienTai, @MaxSecsPerGV = @MaxSecsPerGV, @SoGVMoiLan = @SoGVMoiLan,
        @ChiCapNhat = 1, @TrangThaiRa = @TrangThaiTG OUTPUT, @SoGVConLaiRa = @SoConTG OUTPUT,
        @RunID = @RunID, @sys_UserID = @sys_UserID;
    IF @TrangThaiTG = 'ConTiepTuc'
    BEGIN
        SELECT @RunID AS RunID, N'ConTiepTuc' AS TrangThaiCuoiCung, @SoConTG AS SoGVConLai, 0 AS SoGVKhongDuCho;
        RETURN;
    END

    EXEC spAPI_TkbGiaiTietDoiTuanTu
        @Khoi = '10,11,12',
        @HocKy = @HocKy,
        @TuanHienTai = @TuanHienTai,
        @MaxSecsPerGV = @MaxSecsPerGV,
        @SoGVMoiLan = @SoGVMoiLan,
        @ChiCumTach = 2,
        @RunID = @RunID,
        @sys_UserID = @sys_UserID;
END
