CREATE PROCEDURE spAPI_TkbRound7_DoKhanHiem
    @Khoi VARCHAR(50) = '',
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecsPerGV INT = 60,
    @MaxSecsPerGVToiDa INT = NULL,
    @MaxSecsPhanConLai INT = 400,
    @RunID INT = NULL,
    @ChayRound4 BIT = 1,
    @SoGVMoiLan INT = 1,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- @SoGVMoiLan (2026-09-12, phat hien qua su co that: 1 lan goi xu ly HET moi GV khan hiem (co the
    -- 100+ GV, moi GV toi 80s) bi TREO THAT SU tren production — request HTTP tu trinh duyet vuot qua
    -- timeout cua gateway/IIS, keo theo HUY LUON cau lenh SQL dang chay phia server (khong "chay ngam"
    -- nhu gia dinh truoc day), TrangThai ket qua ket ket o giua chung, khong bao gio tu hoi phuc). Sua:
    -- MOI LAN GOI chi xu ly toi da @SoGVMoiLan GV (mac dinh 1) roi tra ve NGAY (that su nhanh, an toan
    -- voi moi timeout), UI tu goi lai lien tiep cho toi khi het GV — xem TrangThaiCuoiCung =
    -- 'ConTiepTucRound2' (con GV, goi lai) vs 'DungSauRound2'/da qua Round 4 (thuc su xong).
    IF @SoGVMoiLan IS NULL OR @SoGVMoiLan < 1 SET @SoGVMoiLan = 1;
    -- SUA 2026-09-18 (chuan hoa danh so Round 1-8 lien mach theo dung thu tu chay THAT, thay so cu
    -- nhay coc): doi ten spAPI_TkbXepDoKhanHiem -> spAPI_TkbRound7_DoKhanHiem (day la Round 7 trong so
    -- moi, tuong ung "Round 2" trong CAC COMMENT CU ben duoi — CAN THAN: cum tu "Round 1/2/3/4" xuat
    -- hien trong cac doan giai thich lich su ben duoi la theo mo hinh khai niem CU ("thuat toan 4-Round")
    -- co TRUOC ca cach danh so 1.5a/1.5b/1.6a/1.6b — KHONG phai Round 1-8 hien tai. Anh xa: "Round 1"
    -- (khoa cung khai niem) = Round 1 moi; "Round 2" (khan hiem, chinh la SP nay) = Round 7 moi;
    -- "Round 3" (R24/tiet doi, hard constraint trong solver) khong doi ten vi khong phai 1 SP rieng;
    -- "Round 4" (phan con lai) = Round 8 moi (spAPI_TkbRound8_PhanConLai).
    -- 2026-09-12 (theo dung de xuat nguoi dung — "sap giong nguoi", KHONG chia theo khoi o bat ky
    -- buoc nao): xep TUNG GV mot theo do khan hiem (GV bi ep nhat truoc), rai HET moi lop/vai tro cua
    -- GV do (ke ca Sinh hoat tap trung/SH neu la GVCN) roi khoa ngay truoc khi sang GV ke tiep, cat
    -- ngang moi khoi trong 1 lan chay duy nhat.
    --
    -- SUA 2026-09-25: goi spAPI_TkbChayAuto voi @HopBatBuoc = 0 (truoc la 1). Lich that tuan 8 pha hop TO o 8 cho
    -- (4 GV TD-AN-MT o tieu hoc) nhung KHONG BAO GIO pha hop KHOI; solver moi da co co Cung: hop KHOI tieu hoc
    -- luon cung, hop to = mem (phat x1000 < bo don vi x5000) nen chi pha khi bat kha khang.
    -- Round 1 (khoa cung tuyet doi — HOP qua @HopBatBuoc, GVCamTuyetDoi/_Tuan ca nhan, cau truc cum
    -- tblTKB_CumTach*/tblTKB_CapMonDongBoGio) PHAI lam TRUOC KHI goi SP nay (khong lam trong SP nay).
    --
    -- R24 (cap mon dong bo gio/tiet doi) da la hard constraint san co trong TkbCpSatSolver.cs, tu dong
    -- ap dung moi lan goi spAPI_TkbChayAuto ben duoi, khong can buoc rieng.
    --
    -- Round 8 (phan con lai, GV du da) la buoc CUOI CUNG sau SP nay: 1 lan goi spAPI_TkbChayAuto
    -- KHONG @ChiGV cho toan bo @Khoi, sau khi moi GV khan hiem da duoc khoa xong.

    -- MO TA NGAN: Round 7 — giai TUNG GV MOT theo thu tu Do Khan Hiem tang dan (GV it gio ranh nhat xu
    -- ly truoc), toan truong (khong phan biet khoi/cap). Chay SAU Round 2-6 (khoi 10-12 va 1-9 da xong
    -- phan cum tach + tiet doi). Vi giai RIENG LE tung GV (khong gop chung), it bi "skip" oan hon giai
    -- gop — nhung la thuat toan THAM LAM (greedy): GV xu ly truoc chiem slot truoc, khong biet GV sau
    -- can gi, nen khong dam bao toi uu toan cuc. La buoc CUOI truoc khi sang Round 8.
    IF @MaxSecsPerGV IS NULL OR @MaxSecsPerGV < 10 SET @MaxSecsPerGV = 10;
    IF @MaxSecsPerGV > 120 SET @MaxSecsPerGV = 120; -- moi GV la bai toan nho, khong can lau
    -- @MaxSecsPerGVToiDa (2026-09-12, theo de xuat nguoi dung: "cấp đều thời gian là không hợp lý, vì
    -- lúc đầu nhiều slot dễ sắp, càng về sau khó hơn -> nên cân") — CP-SAT KHONG tu dung som du hoi tu
    -- nhanh (van dung het budget de tim loi giai TOT HON, khong chi "kha thi dau tien"), nen cap DEU
    -- @MaxSecsPerGV cho moi GV la lang phi o GV dau (de) va co the KHONG DU o GV cuoi (kho, it slot con
    -- trong hon nhieu). Neu @MaxSecsPerGVToiDa duoc truyen (>@MaxSecsPerGV), budget THUC TE moi GV se
    -- TANG DAN TUYEN TINH tu @MaxSecsPerGV (GV dau) den @MaxSecsPerGVToiDa (GV cuoi) theo % tien do
    -- (@SoGVDaXongTruocLanNay+@ViTri)/@TongSoGVGoc — xem tinh toan ngay truoc EXEC spAPI_TkbChayAuto.
    -- Mac dinh NULL = giu nguyen hanh vi cu (flat @MaxSecsPerGV cho moi GV).
    IF @MaxSecsPerGVToiDa IS NOT NULL AND @MaxSecsPerGVToiDa < @MaxSecsPerGV SET @MaxSecsPerGVToiDa = @MaxSecsPerGV;
    IF @MaxSecsPerGVToiDa IS NOT NULL AND @MaxSecsPerGVToiDa > 120 SET @MaxSecsPerGVToiDa = 120;

    -- SUA 2026-09-17 (tong quat hoa cung fix voi GVDiem/spAPI_TkbChayAuto — xem comment day du o do):
    -- tinh truoc @tmpGVHop (GV -> tap slot hop to co dinh, tu tblTKB_LichHopCoDinh qua anh xa GV->To)
    -- de cong thuc khan hiem duoi day tru dung ca gio hop, khong chi lich ban ca nhan.
    DECLARE @tmpGVHop TABLE (MaGV VARCHAR(9), Thu INT, Buoi VARCHAR(10), Tiet INT, PRIMARY KEY (MaGV, Thu, Buoi, Tiet));
    ;WITH GVNhomSom AS (
        SELECT MaGV, 'TUNHIEN' AS MaNhom, 'To' AS LoaiNhom FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ tự nhiên%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'NGUVAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ ngữ văn%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'XAHOI', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ xã hội%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'HDTNHN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Hoạt động trải nghiệm%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TOAN', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Toán%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TDANMT', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ thể dục - Quốc phòng - Nghệ thuật%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATIEUHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối Tiểu Học%' AND LaThinhGiang = 0
        UNION ALL SELECT MaGV, 'TATRUNGHOC', 'To' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Tổ Ngoại Ngữ%Khối THCS%' AND LaThinhGiang = 0
        UNION ALL SELECT DISTINCT l.GVCN, l.Khoi, 'KhoiTH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND l.GVCN IS NOT NULL
        UNION ALL SELECT DISTINCT l.GVCN, 'CAP23SH', 'KhoiCap23SH' FROM tblTKB_Lop l WHERE l.Enable = 1 AND l.Khoi IN ('06','07','08','09','10','11','12') AND l.GVCN IS NOT NULL
        UNION ALL SELECT MaGV, 'KT', 'KhoiTruong' FROM tblTKB_GiaoVien WHERE PhongBanChucVu LIKE N'%Khối trưởng%'
    )
    INSERT INTO @tmpGVHop (MaGV, Thu, Buoi, Tiet)
    SELECT DISTINCT gn.MaGV, lh.Thu, lh.Buoi, TRY_CAST(s.value AS INT)
    FROM tblTKB_LichHopCoDinh lh
    INNER JOIN GVNhomSom gn ON gn.LoaiNhom = lh.LoaiNhom AND gn.MaNhom = lh.MaNhom
    CROSS APPLY STRING_SPLIT(lh.TietList, ',') s
    WHERE lh.Enable = 1 AND TRY_CAST(s.value AS INT) <= 5;

    -- Buoc 0: dam bao co RunID lam viec — neu chua co (Round 1 chua tao), tao 1 dong rong.
    IF @RunID IS NULL OR NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        INSERT INTO tblTKB_ChayAutoLog (ThoiGianBatDau, Khoi, MaxSecs, TrangThai, NguoiChay, TuanHienTai, Enable)
        VALUES (SYSUTCDATETIME(), CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END,
                0, N'DangDungRound2', @sys_UserID, @TuanHienTai, 1);
        SET @RunID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- 2026-09-12 (UI 4-Round, polling): danh dau NGAY "dang dung Round 2" cho RunID DA CO SAN
        -- (tu Round 1) — de UI poll thay dung trang thai nay trong suot qua trinh, khong bi nham voi
        -- trang thai tam thoi (DangChay/Optimal/Feasible) cua tung GV con dang duoc xu ly rieng le
        -- ben trong vong lap (xem lai moi vong lap ben duoi).
        UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DangDungRound2' WHERE RunID = @RunID;
    END

    -- Buoc 1: tinh diem linh hoat cho MOI GV co PCGD trong pham vi @Khoi/@HocKy/@TuanHienTai —
    -- diem = so slot con TRONG THAT (45 slot chuan/tuan - so slot da ban, ke ca da khoa Round 1 VA
    -- ket qua da xep cho cac GV xu ly TRUOC trong chinh vong lap nay) / tong so tiet con can day.
    -- Cang THAP = cang khan hiem = xu ly cang som.
    DECLARE @DsGV TABLE (MaGV VARCHAR(9) PRIMARY KEY, TongCan INT, SoKhoi INT, TyLeTietDoi FLOAT, DaXuLy BIT NOT NULL DEFAULT 0);

    -- Loai tru GV day NhomCon cua Cum tach (R23) khoi vong xu ly rieng le theo GV (2026-09-12, phat
    -- hien qua kiem chung that: R23 ep dong bo "active" giua CAC NhomCon cung cum — khi 1 NhomCon dang
    -- duoc giai rieng (@ChiGV) ma NhomCon KHAC cung cum CHUA duoc GV nao xu ly toi (chua khoa, cung
    -- chua nam trong NhuCau lan nay), CP-SAT khong biet gi ve no nen khong the dam bao dong bo dung —
    -- co the dan tu treo hoac xep sai. Cach an toan nhat khong can sua kien truc CP-SAT: NHUNG GV nay
    -- (day it nhat 1 lop la NhomCon cua 1 Cum con Enable) bo qua hoan toan o Round 2, don het sang
    -- Round 4 (giai chung CA KHOI mot lan, luc do MOI NhomCon cung cum deu co mat trong cung 1 lan goi
    -- CP-SAT nen R23 hoat dong dung nhu thiet ke).
    DECLARE @LopNhomCon TABLE (MaLop VARCHAR(10) PRIMARY KEY);
    INSERT INTO @LopNhomCon (MaLop)
    SELECT DISTINCT nc.MaLop FROM tblTKB_CumTach_NhomCon nc
    INNER JOIN tblTKB_CumTach ct ON ct.ID = nc.CumTachID AND ct.Enable = 1;

    ;WITH PCGDLoc AS (
        SELECT pc.MaGV, SUM(pc.SoTietChuanTuan) AS TongCan
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1 AND pc.MaMon <> 'SH'
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV)
          -- SUA 2026-09-12 (theo de xuat nguoi dung, co du lieu that: 36 GV day CA cum tach LAN lop
          -- thuong, co nguoi toi 145 dong lop thuong nhung chi 7 dong cum tach — truoc day bi loai
          -- KHOI Round 2 HOAN TOAN chi vi dinh 1 chut cum tach, keo theo ca 145 dong lop thuong khong
          -- lien quan cung bi don oan sang Round 4, lam phinh to bai toan combined-solve khong can
          -- thiet): doi tu "GV co day BAT KY lop cum tach nao -> loai" sang "GV CON lop cum tach CHUA
          -- duoc khoa (giai qua Round 1.5/spAPI_TkbRound1_5_GiaiCumTach+Khoa) -> moi loai". Sau khi
          -- Round 1.5 khoa cung xong TOAN BO cum tach, dieu kien nay tu dong het hieu luc, GV duoc
          -- nhan lai vao Round 2 cho phan lop thuong con lai cua ho — an toan vi R23 chi can dong bo
          -- LUC GIAI (da xong o Round 1.5), khong con rang buoc gi voi Round 2 nua.
          AND NOT EXISTS (
              SELECT 1 FROM tblTKB_PhanCongGiangDay pc2
              INNER JOIN @LopNhomCon nc2 ON nc2.MaLop = pc2.MaLop
              WHERE pc2.Enable = 1 AND pc2.MaGV = pc.MaGV
                AND NOT EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep k2
                    WHERE k2.RunID = @RunID AND k2.MaLop = pc2.MaLop AND k2.MaMon = pc2.MaMon AND k2.MaGV = pc2.MaGV
                )
          )
          -- SUA 2026-09-12 (BUG NGHIEM TRONG phat hien qua thuc te — RunID 1255 dung yen o GV 96/99
          -- HANG GIO): tu khi chia nho @SoGVMoiLan qua nhieu lan goi HTTP rieng biet (fix truoc do cho
          -- van de treo timeout), moi lan goi deu XAY DUNG LAI @DsGV tu dau — neu 1 GV co (Lop,Mon)
          -- solver KHONG BAO GIO xep duoc (vd 06G/ENG1 that su khong con cho trong), NOT EXISTS ben tren
          -- KHONG BAO GIO true cho combo do, GV nay VINH VIEN la "khan hiem nhat" moi lan tinh lai — bi
          -- CHON LAI VO HAN, khong bao gio tien qua GV ke tiep (khac han thiet ke ban dau: 1 lan goi DUY
          -- NHAT xu ly HET moi GV, dung @DsGV/DaXuLy trong BO NHO de dam bao moi GV CHI THU 1 LAN duy
          -- nhat du thanh cong hay khong — bao dam nay MAT khi tach thanh nhieu lan goi HTTP rieng biet,
          -- moi lan la 1 phien SQL moi, khong con nho GV nao da thu qua). Sua: dung bang
          -- tblTKB_Round2DaXuLy (RunID,MaGV) BEN NGOAI vong doi cua 1 lan goi de nho VINH VIEN GV nao
          -- DA TUNG duoc chon xu ly trong Round 2 nay (du thanh cong hay khong) — loai han khoi @DsGV
          -- moi lan tinh lai, dam bao MOI GV CHI duoc chon dung 1 LAN trong suot Round 2, giong dung
          -- bao dam cua thiet ke ban dau.
          AND NOT EXISTS (SELECT 1 FROM tblTKB_Round2DaXuLy dxl WHERE dxl.RunID = @RunID AND dxl.MaGV = pc.MaGV)
        GROUP BY pc.MaGV
        HAVING SUM(pc.SoTietChuanTuan) > 0
    )
    -- SUA 2026-09-13 (dong bo voi Round 1.5/spAPI_TkbChayAuto.GVDiem — theo de xuat nguoi dung sau
    -- khi phat hien cong thuc Round 2 cu thieu 2 yeu to: (a) SoKhoi — GV day cheo nhieu khoi kho xep
    -- hon GV cung tong tiet nhung chi 1 khoi (vd Hoang Thanh Quang), (b) tiet doi — GV day toan tiet
    -- doi kho xep hon GV tiet don cung so luong vi can DUNG 2 slot lien tiep). Them 2 cot @SoKhoi/
    -- @TyLeTietDoi, tinh tren TOAN BO PCGD cua GV (khong gioi han @Khoi/con lai — phan anh dung do
    -- kho THAT cua GV, giong het GVDiem).
    INSERT INTO @DsGV (MaGV, TongCan, SoKhoi, TyLeTietDoi)
    SELECT p.MaGV, p.TongCan,
           (SELECT COUNT(DISTINCT l3.Khoi) FROM tblTKB_PhanCongGiangDay pc3
            INNER JOIN tblTKB_Lop l3 ON l3.MaLop = pc3.MaLop
            WHERE pc3.Enable = 1 AND pc3.MaMon <> 'SH' AND pc3.MaGV = p.MaGV
              AND (@HocKy = '' OR pc3.HocKy = @HocKy)
              AND (@TuanHienTai IS NULL OR pc3.TuanApDungTu IS NULL OR @TuanHienTai >= pc3.TuanApDungTu)
              AND (@TuanHienTai IS NULL OR pc3.TuanApDungDen IS NULL OR @TuanHienTai <= pc3.TuanApDungDen)
              AND (@TuanHienTai IS NULL OR pc3.ApDungTuanChan IS NULL OR pc3.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
           ) AS SoKhoi,
           ISNULL((SELECT CAST(SUM(CASE WHEN mh3.BatBuocXepDoi = 1 THEN pc3.SoTietChuanTuan ELSE 0 END) AS FLOAT) / NULLIF(SUM(pc3.SoTietChuanTuan), 0)
            FROM tblTKB_PhanCongGiangDay pc3
            LEFT JOIN tblTKB_MonHoc mh3 ON mh3.MaMon = pc3.MaMon
            WHERE pc3.Enable = 1 AND pc3.MaMon <> 'SH' AND pc3.MaGV = p.MaGV
              AND (@HocKy = '' OR pc3.HocKy = @HocKy)
              AND (@TuanHienTai IS NULL OR pc3.TuanApDungTu IS NULL OR @TuanHienTai >= pc3.TuanApDungTu)
              AND (@TuanHienTai IS NULL OR pc3.TuanApDungDen IS NULL OR @TuanHienTai <= pc3.TuanApDungDen)
              AND (@TuanHienTai IS NULL OR pc3.ApDungTuanChan IS NULL OR pc3.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
           ), 0) AS TyLeTietDoi
    FROM PCGDLoc p;

    -- Nhat ky tien do de tra ve cuoi cung.
    DECLARE @NhatKy NVARCHAR(MAX) = N'';
    DECLARE @TongSoGV INT = (SELECT COUNT(*) FROM @DsGV); -- so GV CON LAI tinh lai lan goi nay (khong phai tong goc)
    SET @NhatKy = N'Round 2: ' + CAST(@TongSoGV AS NVARCHAR(10)) + N' GV con lai (RunID=' + CAST(@RunID AS NVARCHAR(10)) + N').' + CHAR(13);

    -- Tong so GV GOC (2026-09-12, ho tro chia nho @SoGVMoiLan qua nhieu lan goi): luu 1 LAN DUY NHAT
    -- vao TongSoGV cua tblTKB_ChayAutoLog o LAN GOI DAU TIEN (khi con NULL) — cac lan goi lai sau (resume,
    -- @TongSoGV o tren da tu giam vi cac GV truoc da bi loai khoi @DsGV) doc lai dung gia tri goc nay de
    -- hien thi "vi tri toan cuc" on dinh, khong "nhay lui ve 1" moi lan goi lai.
    DECLARE @TongSoGVGoc INT = (SELECT TongSoGV FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    IF @TongSoGVGoc IS NULL
    BEGIN
        SET @TongSoGVGoc = @TongSoGV;
        UPDATE tblTKB_ChayAutoLog SET TongSoGV = @TongSoGVGoc WHERE RunID = @RunID;
    END
    DECLARE @SoGVDaXongTruocLanNay INT = @TongSoGVGoc - @TongSoGV;

    -- Buoc 2: lap qua tung GV theo diem linh hoat TANG DAN (khan hiem nhat truoc) — diem tinh LAI
    -- moi vong (dua vao so slot GV do da bi chiem boi HOP/GVCamTuyetDoi/ket qua cac GV xu ly truoc).
    -- Chi xu ly toi da @SoGVMoiLan GV trong 1 lan goi nay (xem giai thich o dau SP).
    DECLARE @ViTri INT = 1, @GVDangXu VARCHAR(9), @RunGV INT, @TrangThaiGV NVARCHAR(50), @WaitedSecs INT;
    DECLARE @DaXuLyLanNay INT = 0;

    WHILE @ViTri <= @TongSoGV AND @DaXuLyLanNay < @SoGVMoiLan
    BEGIN
        -- Chon GV co diem linh hoat THAP NHAT trong so CHUA xu ly.
        -- SUA 2026-09-13 (dong bo Round 1.5): chia them SoKhoi (dạy chéo khối càng nhiều càng khan
        -- hiếm) và (1 + TyLeTietDoi) (tiết đôi càng nhiều càng khan hiếm) — cùng công thức GVDiem.
        -- SUA 2026-09-16 (tong quat hoa cung fix voi GVDiem trong spAPI_TkbChayAuto — xem comment day
        -- du o do): UNION them tblTKB_GVCamTuyetDoi_Tuan theo @TuanHienTai, vi tblTKB_GVCamTuyetDoi
        -- (theo RunID) THUC TE luon rong tru khi co "Bao ban" tuong tac, khien GV co lich ban dai han
        -- (thinh giang) bi tinh diem khan hiem cao hon that, khong duoc uu tien dung dau hang cho.
        SELECT TOP 1 @GVDangXu = d.MaGV
        FROM @DsGV d
        WHERE d.DaXuLy = 0
        ORDER BY (
            45.0 - (
                SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaGV = d.MaGV
            ) - (
                SELECT COUNT(DISTINCT CONCAT(Thu,'-',Buoi,'-',Tiet)) FROM (
                    SELECT Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID AND MaGV = d.MaGV
                    UNION
                    SELECT g.Thu, bb.Buoi, tt.Tiet
                    FROM tblTKB_GVCamTuyetDoi_Tuan g
                    CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
                    CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
                    WHERE g.MaGV = d.MaGV AND g.Tuan = @TuanHienTai
                    UNION
                    SELECT h.Thu, h.Buoi, h.Tiet FROM @tmpGVHop h WHERE h.MaGV = d.MaGV
                ) camGop
            )
        ) / NULLIF(d.TongCan, 0) / NULLIF(d.SoKhoi, 0) / (1.0 + ISNULL(d.TyLeTietDoi, 0)) ASC;

        IF @GVDangXu IS NULL BREAK;

        -- Ghi lai GV dang xu ly + vi tri TOAN CUC/tong so GOC (2026-09-12, theo de xuat nguoi dung "show
        -- ten nguoi ra moi lan chay") — de UI poll qua spAPI_TkbRoundThongKe biet dung dang xu ly ai, vi
        -- tri may/tong bao nhieu (on dinh qua nhieu lan goi @SoGVMoiLan, khong dung @ViTri/@TongSoGV cuc
        -- bo cua rieng lan goi nay vi 2 gia tri do tu giam dan qua moi lan resume). Ghi TRUOC khi goi
        -- spAPI_TkbChayAuto (SP do khong dung toi cac cot nay nen an toan, khong bi ghi de).
        UPDATE tblTKB_ChayAutoLog SET GVDangXuLy = @GVDangXu, ViTriGV = @SoGVDaXongTruocLanNay + @ViTri, TongSoGV = @TongSoGVGoc
        WHERE RunID = @RunID;

        -- XoayTro (2026-09-12, theo de xuat nguoi dung): luu lai "diem linh hoat" cua GV nay TAI DUNG
        -- THOI DIEM khoa (0-100, cang thap cang kho gia lai neu go ra sau nay) — dung LAI chinh cong
        -- thuc xep hang o tren, khong tinh them gi moi. Day la snapshot, se cu dan theo thoi gian (cac
        -- GV xu ly sau se khoa them xung quanh) — dung de LOC SO BO khi can go ra sua sau, KHONG dung
        -- lam con so tuyet doi; muon chinh xac tai thoi diem go phai tinh lai truc tiep (spAPI_TkbGoThoTheoXoayTro).
        DECLARE @DiemLinhHoat FLOAT, @XoayTroGV TINYINT;
        SELECT @DiemLinhHoat = (
            45.0 - (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu)
                 - (SELECT COUNT(DISTINCT CONCAT(Thu,'-',Buoi,'-',Tiet)) FROM (
                       SELECT Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID AND MaGV = @GVDangXu
                       UNION
                       SELECT g.Thu, bb.Buoi, tt.Tiet
                       FROM tblTKB_GVCamTuyetDoi_Tuan g
                       CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
                       CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
                       WHERE g.MaGV = @GVDangXu AND g.Tuan = @TuanHienTai
                       UNION
                       SELECT h.Thu, h.Buoi, h.Tiet FROM @tmpGVHop h WHERE h.MaGV = @GVDangXu
                   ) camGop2)
        ) / NULLIF((SELECT d2.TongCan FROM @DsGV d2 WHERE d2.MaGV = @GVDangXu), 0)
          / NULLIF((SELECT d2.SoKhoi FROM @DsGV d2 WHERE d2.MaGV = @GVDangXu), 0)
          / (1.0 + ISNULL((SELECT d2.TyLeTietDoi FROM @DsGV d2 WHERE d2.MaGV = @GVDangXu), 0));
        SET @XoayTroGV = CAST(
            CASE WHEN @DiemLinhHoat IS NULL THEN 50
                 WHEN @DiemLinhHoat < 0 THEN 0
                 WHEN @DiemLinhHoat > 1 THEN 100
                 ELSE @DiemLinhHoat * 100 END
        AS TINYINT);

        -- Budget dong theo tien do (xem giai thich o dau SP) — GV cang ve sau (con it slot trong hon)
        -- cang duoc cap nhieu thoi gian tim kiem hon, thay vi cap DEU cho moi GV.
        DECLARE @MaxSecsGVNay INT = @MaxSecsPerGV;
        IF @MaxSecsPerGVToiDa IS NOT NULL AND @TongSoGVGoc > 1
            SET @MaxSecsGVNay = @MaxSecsPerGV + CAST(
                (@MaxSecsPerGVToiDa - @MaxSecsPerGV) * (@SoGVDaXongTruocLanNay + @ViTri - 1) / (@TongSoGVGoc - 1)
            AS INT);

        EXEC spAPI_TkbChayAuto @Khoi = @Khoi, @HocKy = @HocKy, @MaxSecs = @MaxSecsGVNay,
             @HopBatBuoc = 0, @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID,
             @ChiGV = @GVDangXu, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

        SET @RunGV = @RunID; -- @RunIDDangXay giu nguyen @RunID (khong tao RunID moi)
        SET @TrangThaiGV = N'DangChay'; SET @WaitedSecs = 0;
        WHILE @TrangThaiGV = N'DangChay' AND @WaitedSecs < (@MaxSecsGVNay + 60)
        BEGIN
            WAITFOR DELAY '00:00:01';
            SET @WaitedSecs = @WaitedSecs + 1;
            EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunGV, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
            SELECT @TrangThaiGV = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunGV;
        END

        -- Khoa NGAY moi dong vua xep cho GV nay (bat ke lop/khoi nao) truoc khi sang GV ke tiep —
        -- day la buoc BAT BUOC de dam bao GV xu ly sau khong the "danh mat" slot cua GV nay.
        UPDATE k SET XoayTro = @XoayTroGV
        FROM tblTKB_KetQuaXep k
        WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu AND k.XoayTro IS NULL;

        -- KHOA TAM (2026-09-19): ghi lai chinh xac cac dong DO ROUND 7 khoa (chua bi khoa tu round truoc)
        -- de cuoi Round 7 mo khoa lai cho GV linh hoat — xem khoi "Mo khoa tam" ben duoi.
        INSERT INTO tblTKB_Round7KhoaTam (KetQuaXepID, RunID, MaGV)
        SELECT k.ID, @RunID, k.MaGV FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu AND kh.KetQuaXepID IS NULL
          AND NOT EXISTS (SELECT 1 FROM tblTKB_Round7KhoaTam t0 WHERE t0.KetQuaXepID = k.ID);

        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT k.ID FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu AND kh.KetQuaXepID IS NULL;

        -- Dat lai dung cot "dang dung Round 2" NGAY sau khi 1 GV xong — trong luc nay TrangThai vua
        -- bi chinh EXEC spAPI_TkbChayAuto/TrangThai o tren ghi de thanh trang thai rieng cua GV do
        -- (Optimal/Feasible/...), can ghi de lai NGAY de UI dang poll khong nham "1 GV xong" voi
        -- "toan bo Round 2 xong".
        UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DangDungRound2' WHERE RunID = @RunID;

        SET @NhatKy = @NhatKy + N'  [' + CAST(@ViTri AS NVARCHAR(10)) + N'/' + CAST(@TongSoGV AS NVARCHAR(10)) + N'] GV=' + @GVDangXu
            + N', TrangThai=' + ISNULL(@TrangThaiGV, N'?')
            + N', SoNhomKhongXepDuoc=' + CAST((SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID AND MaGV = @GVDangXu) AS NVARCHAR(10))
            + CHAR(13);

        UPDATE @DsGV SET DaXuLy = 1 WHERE MaGV = @GVDangXu; -- danh dau da xu ly, khong chon lai (trong lan goi nay)
        -- Ghi nhan VINH VIEN (ben ngoai vong doi 1 lan goi) — xem giai thich o dau SP tai doan loc @DsGV.
        INSERT INTO tblTKB_Round2DaXuLy (RunID, MaGV, ThoiGian) VALUES (@RunID, @GVDangXu, SYSUTCDATETIME());
        SET @ViTri = @ViTri + 1;
        SET @DaXuLyLanNay = @DaXuLyLanNay + 1;
    END

    -- Dung lai giua chung vi da cham tran @SoGVMoiLan cua LAN GOI NAY, nhung VAN CON GV khac trong danh
    -- sach (2026-09-12) — tra ve NGAY (khong cho Round 4), UI thay 'ConTiepTucRound2' se tu goi lai SP
    -- nay (cung @RunID) de xu ly tiep GV ke tiep, tranh 1 lan goi qua dai gay treo (xem giai thich dau SP).
    IF @ViTri <= @TongSoGV
    BEGIN
        UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DangDungRound2' WHERE RunID = @RunID;
        SELECT @RunID AS RunID, N'ConTiepTucRound2' AS TrangThaiCuoiCung,
               (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID) AS SoNhomKhongXepDuoc,
               @SoGVDaXongTruocLanNay + @ViTri - 1 AS SoGVDaXuLyRieng, @TongSoGVGoc AS TongSoGV, @NhatKy AS NhatKy;
        RETURN;
    END

    -- MO KHOA TAM (2026-09-19, theo huong 1 da thong nhat sau khi RunID 1318 cho thay 100% tiet khoi 01-09
    -- deu bi Round 7 khoa cung -> Round 8 (xoa + xep lai theo lop) khong con gi de doi cho, chi ~4% phan du
    -- "dong bang" tu Round 7). Round 7 van CAN khoa tung GV trong luc chay (GV sau khong duoc de len GV
    -- truoc) — nhung khi da het GV thi ket qua cua GV LINH HOAT (khong thinh giang, khong co lich cam theo
    -- tuan) duoc mo khoa de Round 8 co the xoa va xep lai. GV thinh giang / co lich cam tuan giu nguyen
    -- khoa (day chinh la nhom Round 7 can bao ve — mat khoa la Round 8 co the lam mat cho cua ho). Tiet
    -- doi (Round 3/5/6) va khoa cung Round 1 KHONG nam trong bang nay nen luon giu khoa.
    -- CHI mo khoa dong cua lop khoi 01-09 (RunID 1327: mo ca khoi 10-12 lam Round 8 giai lai te hon giu
    -- nguyen ket qua Round 7 — mat 6 tiet — vi khoi 10-12 da co Round 2-4 chuyen dung).
    DELETE kh FROM tblTKB_KetQuaXep_Khoa kh
    INNER JOIN tblTKB_Round7KhoaTam t ON t.KetQuaXepID = kh.KetQuaXepID
    INNER JOIN tblTKB_GiaoVien g ON g.MaGV = t.MaGV
    INNER JOIN tblTKB_KetQuaXep kq ON kq.ID = t.KetQuaXepID
    INNER JOIN tblTKB_Lop lp ON lp.MaLop = kq.MaLop AND lp.Khoi < '10'
    WHERE t.RunID = @RunID AND g.LaThinhGiang = 0
      AND NOT EXISTS (SELECT 1 FROM tblTKB_GVCamTuyetDoi_Tuan c WHERE c.MaGV = t.MaGV AND c.Tuan = @TuanHienTai);
    DELETE t FROM tblTKB_Round7KhoaTam t
    WHERE t.RunID = @RunID AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa kh WHERE kh.KetQuaXepID = t.KetQuaXepID);

    -- Buoc 3 (Round 4): phan con lai (GV du da, GVCN tieu hoc linh hoat) giao CP-SAT giai 1 LAN cho
    -- TOAN BO @Khoi cung luc — khong gian con lai la rong nhat trong toan bo quy trinh sau khi moi GV
    -- khan hiem da khoa xong. @ChayRound4=0 (2026-09-12, theo de xuat UI 4-Round co the dung lai xem
    -- tung buoc): dung LAI DAY, khong giai phan con lai — de nguoi dung tu bam "Round 4" rieng sau
    -- khi da xem xet ky ket qua Round 2 (vd goi truc tiep spAPI_TkbChayAutoPhanConLai @RunID nay).
    IF @ChayRound4 = 0
    BEGIN
        SET @NhatKy = @NhatKy + N'Dung sau Round 2 theo yeu cau (@ChayRound4=0) — chua giai phan con lai.' + CHAR(13);
        -- Xoa GVDangXuLy khi Round 2 da xong het (khong con dang xu ly ai nua) — tranh UI hien nham
        -- "dang xu ly GV X" sau khi that ra da dung hoan toan.
        UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DungSauRound2', GVDangXuLy = NULL WHERE RunID = @RunID;
        SELECT @RunID AS RunID, N'DungSauRound2' AS TrangThaiCuoiCung,
               (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID) AS SoNhomKhongXepDuoc,
               @TongSoGV AS SoGVDaXuLyRieng, @NhatKy AS NhatKy;
        RETURN;
    END

    DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (
        SELECT k.ID FROM tblTKB_KetQuaXep k LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND kh.KetQuaXepID IS NULL
    ); -- no-op (chi de dam bao khong con rac chua khoa truoc buoc cuoi), an toan vi cac dong that su
       -- can giu deu da duoc INSERT vao Khoa o vong lap tren.

    EXEC spAPI_TkbChayAuto @Khoi = @Khoi, @HocKy = @HocKy, @MaxSecs = @MaxSecsPhanConLai,
         @HopBatBuoc = 0, @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

    SET @TrangThaiGV = N'DangChay'; SET @WaitedSecs = 0;
    WHILE @TrangThaiGV = N'DangChay' AND @WaitedSecs < (@MaxSecsPhanConLai + 60)
    BEGIN
        WAITFOR DELAY '00:00:08';
        SET @WaitedSecs = @WaitedSecs + 8;
        EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @XoayTroMacDinh = 90, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
        SELECT @TrangThaiGV = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
    END

    SET @NhatKy = @NhatKy + N'Round 4 (phan con lai, toan bo @Khoi): TrangThai=' + ISNULL(@TrangThaiGV, N'?')
        + N', SoNhomKhongXepDuoc cuoi cung=' + CAST((SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID) AS NVARCHAR(10)) + CHAR(13);

    SELECT @RunID AS RunID, @TrangThaiGV AS TrangThaiCuoiCung,
           (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID) AS SoNhomKhongXepDuoc,
           @TongSoGV AS SoGVDaXuLyRieng, @NhatKy AS NhatKy;
END
