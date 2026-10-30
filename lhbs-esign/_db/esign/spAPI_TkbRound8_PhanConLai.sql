CREATE PROCEDURE spAPI_TkbRound8_PhanConLai
    @RunID INT,
    @MaxSecs INT = 60,
    @HocKy VARCHAR(4) = 'HK1',
    @KhoiLoc VARCHAR(50) = '',
    @MaxSecsPerLop INT = 60,
    @SoLopMoiLan INT = 15,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- SUA 2026-09-18 (thiet ke moi, xem spAPI_TkbGiaiLopThuongTuanTu): doan XOA + warm-start snapshot
    -- GIU NGUYEN (van dung — "pha don vi da xep de nhuong cho" van can co, khong lien quan gi toi don
    -- vi giai tuan tu). Chi doi BUOC GIAI CUOI CUNG (sau khi da xoa) tu 1 EXEC gop toan @Khoi sang goi
    -- engine giai TUNG LOP mot — cung ly do da chung minh dung o Round 4 (TOAN bi "an" giua dam dong khi
    -- giai gop nhieu mon/nhieu lop cung luc, du GV khong qua tai).
    -- SUA 2026-09-18 (chuan hoa danh so Round lien mach 1-8 theo dung thu tu chay THAT, thay cho danh
    -- so cu nhay coc "1, 1.5a, 1.5c, 1.5b, 1.6a, 1.6b, 2, 4" gay nham lan): doi ten tu
    -- spAPI_TkbChayAutoPhanConLai -> spAPI_TkbRound8_PhanConLai (tuong ung "Round 4" cu). Khong doi
    -- logic, chi doi ten + so hieu round trong comment.
    -- MO TA NGAN: Round 8 — buoc CUOI CUNG, XOA cac tiet CHUA khoa tay + giai lai TOAN BO (khong chi
    -- them vao cho trong, ma duoc PHA don vi da xep de nhuong cho) trong pham vi @KhoiLoc. Chi round
    -- nay moi co the sua cac loi "cho da bi chiem het" ma Round 7 (chi them, khong pha) khong cuu duoc.
    -- Thuong chay 2 lan: khoi 10-12 truoc (R23/R24 phuc tap nhat, can nhieu thoi gian rieng), roi phan
    -- con lai (01-09) sau.
    -- @KhoiLoc (2026-09-12, theo de xuat nguoi dung "tach Round 4 thanh 2 lan — khoi 10-12 rieng, phan
    -- con lai rieng" — khoi 10-12 co Cum tach R23 + Cap mon dong bo R24 phuc tap nhat, don rieng 1 lan
    -- giai voi @MaxSecs rieng du lau hon thay vi gop chung 1 lan 400s cho toan truong): rong (mac dinh,
    -- KHONG doi hanh vi cu) = xoa/giai lai TOAN BO khoi dang co trong RunID nhu truoc; co gia tri = CHI
    -- xoa/giai lai cac lop THUOC @KhoiLoc, giu nguyen (khong dung toi) cac khoi khac dang co trong RunID.
    -- tAPI bind key vang mat trong JSON body thanh NULL thay vi dung default cua T-SQL (da gap dung
    -- loi nay o spAPI_TkbKetQuaXepList) — @HocKy/@MaxSecs co the ve NULL neu UI khong gui, phai
    -- coalesce lai truoc khi dung, neu khong (@HocKy = '' OR pc.HocKy = @HocKy) trong spAPI_TkbChayAuto
    -- se UNKNOWN cho moi dong va loc sach toan bo NhuCau.
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');
    SET @MaxSecs = ISNULL(@MaxSecs, 60);
    -- "Xep Auto phan con thieu" (2026-09-02) — dung cho tkb-sua-tay: nguoi dung da xep tay/keo-tha 1
    -- phan va bam khoa (tblTKB_KetQuaXep_Khoa), phan CHUA khoa (kha nang tu 1 lan Auto truoc do, chua
    -- chac muon giu) se bi xoa va dua tro lai thanh nhu cau cho Auto tu do xep lai. SH khong dong
    -- trong Khoa (khong ai chu dong khoa no qua UI) nhung van duoc giu nguyen vi no da tu bao ve rieng
    -- qua co che auto-khoa cua spAPI_TkbChayAuto — xoa roi no se duoc chen lai y het, khong can loai tru
    -- o day nhung loai tru van de tranh xoa/chen thua khong can thiet.

    IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               N'Không tìm thấy lần chạy này' AS ThongBao;
        RETURN;
    END

    DECLARE @Khoi VARCHAR(50), @TuanHienTai INT;
    SELECT @TuanHienTai = TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    -- Lay lai danh sach Khoi THAT tu chinh cac lop dang co trong RunID (cot Khoi trong ChayAutoLog co
    -- the bi rut gon dang '06+' khi gop nhieu khoi, khong dung lai chinh xac duoc).
    SELECT @Khoi = STRING_AGG(x.Khoi, ',') FROM (
        SELECT DISTINCT l.Khoi
        FROM tblTKB_KetQuaXep k
        INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
        WHERE k.RunID = @RunID
          AND (@KhoiLoc = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiLoc, ',')))
    ) x;

    IF @Khoi IS NULL OR @Khoi = ''
    BEGIN
        SELECT @RunID AS RunID, N'KhongCoDuLieu' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               N'RunID này chưa có tiết nào để xác định khối, không thể chạy tiếp' AS ThongBao;
        RETURN;
    END

    -- Warm-start (2026-09-12, theo de xuat nguoi dung "nang cao kha nang xep, giam go tay"): truoc khi
    -- xoa phan chua khoa, chup lai TOAN BO loi giai HIEN TAI (ke ca phan sap bi xoa) vao 1 RunID "shadow"
    -- rieng (Enable=0, an khoi moi listing/dropdown) — dung lam @RunIDGoiY cho spAPI_TkbChayAuto, giup
    -- CP-SAT hoi tu nhanh hon nhieu (bat dau tu 1 loi giai gan-dung) thay vi giai lai tu con so 0 moi
    -- lan "Gỡ và xếp lại"/chay lai Round 4. Chi mot snapshot RIENG cho lan chay nay, khong anh huong
    -- RunID chinh — an toan xoa don don ve sau (khong ai tham chieu toi ngoai chinh cau lenh nay).
    -- FIX (2026-09-16, phat hien qua test that RunID 1284): cot Khoi trong tblTKB_ChayAutoLog chi
    -- VARCHAR(2) — gia tri 'WARMSTART' (9 ky tu) luon gay loi truncation, khien CA insert nay LAN
    -- insert KetQuaXep phia duoi (dua vao @RunIDGoiY=NULL do SCOPE_IDENTITY() khong co gia tri) that
    -- bai, huy toan bo SP (may man DELETE ben duoi chua kip chay nen khong mat du lieu that). Dung
    -- 'WS' (2 ky tu, vua khop) thay cho 'WARMSTART'.
    DECLARE @RunIDGoiY INT;
    INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
    VALUES (SYSUTCDATETIME(), N'WS', 0, N'WarmStartSnapshot', @sys_UserID, @TuanHienTai, 0);
    SET @RunIDGoiY = SCOPE_IDENTITY();

    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT @RunIDGoiY, k.MaLop, k.Thu, k.Buoi, k.Tiet, k.MaMon, k.MaGV, k.MaPhong, k.XoayTro
    FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    WHERE k.RunID = @RunID AND k.MaMon <> 'KHOAPHONG'
      AND (@KhoiLoc = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiLoc, ',')));

    DELETE k FROM tblTKB_KetQuaXep k
    INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
    WHERE k.RunID = @RunID AND k.MaMon <> 'SH'
      AND k.ID NOT IN (SELECT KetQuaXepID FROM tblTKB_KetQuaXep_Khoa)
      AND (@KhoiLoc = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiLoc, ',')));

    EXEC spAPI_TkbGiaiLopThuongTuanTu
        @Khoi = @Khoi,
        @HocKy = @HocKy,
        @TuanHienTai = @TuanHienTai,
        @MaxSecsPerLop = @MaxSecsPerLop,
        @SoLopMoiLan = @SoLopMoiLan,
        @Nhom = 'R8',
        @RunID = @RunID,
        @sys_UserID = @sys_UserID;
END
