CREATE PROCEDURE spAPI_TkbChayAuto
    @Khoi VARCHAR(50) = '',
    @HocKy VARCHAR(4) = 'HK1',
    @MaxSecs INT = 60,
    @R4BatBuoc BIT = 0,
    @R9BatBuoc BIT = 0,
    @R7BatBuoc BIT = 0,
    @R22BatBuoc BIT = 0,
    @HopBatBuoc BIT = 0,
    @TuanHienTai INT = NULL,
    @RunIDDangXay INT = NULL,
    @RunIDGoiY INT = NULL,
    -- 2026-10-10 (va doi cho cuc bo): neo tung tiet vao vi tri trong 1 lan chay (ban sao vung truoc khi va) thay vi tuan nguon.
    @RunIDNeo INT = NULL,
    @PhatNeoRun INT = 60,
    @ChiGV VARCHAR(9) = NULL,
    @ChiLop VARCHAR(1000) = NULL,
    @ChiMon VARCHAR(100) = NULL,
    @ChiMonDoi BIT = 0,
    -- 2026-10-07: GV "hep gio" (it o ranh so voi so tiet) duoc dua THEM vao buoc xep truoc (cung @ChiMon/@ChiMonDoi).
    @ThemGV VARCHAR(500) = NULL,
    @ChiCumTach TINYINT = 0,
    @KhongChoSkip BIT = 0,
    @ChiTraVeBody BIT = 0,
    -- SUA 2026-09-22 (phat hien qua chay that RunID 1337, Round 6 — goc re that su cua loi '⚠️
    -- Khong xac dinh duoc trang thai tra ve' UI hay gap): SP nay LUON ket thuc bang 1 SELECT tra
    -- {RunID,TrangThai,KhaThi,ThongBao} (dong ~870, nhanh 'DangChay' binh thuong, chay MOI LAN goi
    -- thanh cong). Khi duoc goi TU BEN TRONG vong lap cua spAPI_TkbGiaiTietDoiTuanTu/
    -- GiaiLopThuongTuanTu/Round7/Round9/ChayAutoThongMinh (goi 1 lan cho MOI GV/lop, khong phai
    -- 1 lan cho ca RunID), result set nay xuat hien SOM HON SELECT CUOI CUNG dinh nghia boi SP goi
    -- no, va tAPI/driver SQL CHI DOC RESULT SET DAU TIEN cua ca chuoi goi long nhau -> UI doc NHAM
    -- thanh ket qua cuoi cung (hien loi) DU cong viec (giai, khoa, ghi tracking) van chay tiep va
    -- thanh cong binh thuong phia sau. @ChiCapNhat=1: bo qua toan bo SELECT tra ket qua (chi
    -- INSERT/UPDATE nhu binh thuong) — dung khi goi TU BEN TRONG 1 SP khac. Mac dinh =0 (khong doi
    -- hanh vi o moi noi khac).
    @ChiCapNhat BIT = 0,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- @ChiMonDoi (2026-09-13, theo de xuat nguoi dung "Round 1.6" — sau khi phat hien qua RunID 1269:
    -- 22/62 nhom con ket ket sau Round 2+4 la mon BatBuocXepDoi=1 (ENG2/STEM/GDQP), du VAN CON slot
    -- rong hop le cho ca GV lan lop (kiem chung truc tiep — vd GV Le Thi Ngoc Linh con slot doi Thu2-
    -- Chieu4+5 rong ca 2 ben nhung khong duoc dung) — nguyen nhan: Round 2 xep TUNG GV mot theo do khan
    -- hiem, cac mon tiet don (TOAN/TV/VAN...) cua GV khac co the "an" mat 1 nua cua 1 cap slot lien
    -- tiep truoc khi den luot GV can tiet doi, pha vo kha nang ghep doi ma 1 lan giai gop se tranh duoc
    -- (giong dung ly do Round 1.5 tach rieng cum tach AV/chuyen de khoi 10-12 truoc Round 2). Khi bat,
    -- PCGDLoc CHI gom cac (Lop,Mon,GV) co MaMon thuoc mon BatBuocXepDoi=1 — dung cho Round 1.6 (khoi
    -- 1-9, TRUOC Round 2) de giai gop toan bo nhu cau tiet doi khi ban co con trong nhat.
    -- @ChiCumTach (2026-09-15, theo de xuat nguoi dung, tach Round 1.5 thanh 1.5a/1.5b giong cach
    -- Round 1.6 da tach khoi Round 2): 0=khong loc (mac dinh, hanh vi cu — giai chung ca cum tach LAN
    -- lop thuong 1 lan). 1=CHI lay PCGD thuoc cum tach (LaCumTach=1, dung cho Round 1.5a — giai truoc
    -- khi ban co con trong nhat, giam khong gian tim kiem cho dung 81/362 dong thuc te khoi 10-12).
    -- 2=CHI lay PCGD KHONG thuoc cum tach (dung cho Round 1.5b — giai phan lop thuong sau khi 1.5a da
    -- khoa cung cum tach, khong con phai canh tranh khong gian tim kiem voi rang buoc dong bo R23/R24).
    -- @ChiTraVeBody (2026-09-12, ho tro chay solver THU CONG tren may local nhieu core hon thay vi
    -- Docker production 4 core): khi bat, CHI tra ve @Body JSON se gui cho solver (dung HET logic
    -- tinh NhuCau/LopDaKhoa/CumTach/... y het lan chay that), KHONG goi httpCall, KHONG dong/sua
    -- tblTKB_ChayAutoLog — hoan toan "doc", an toan goi nhieu lan de debug/trich xuat.

    IF @MaxSecs IS NULL OR @MaxSecs < 10 SET @MaxSecs = 10;
    -- Tran nang tu 240 -> 600s (2026-08-29): thu nghiem gop nhieu khoi (vd 04+05) can nhieu thoi
    -- gian tim kiem hon han giai rieng tung khoi do khong gian bai toan lon hon nhieu (SoNhuCau
    -- tang theo cap so nhan) — 240s khong du de tan dung warm-start tot nhu khi giai rieng.
    -- Tran nang tu 600 -> 1200s (2026-09-13, theo de xuat nguoi dung): production Docker chi co 4
    -- core (so voi may local 8 core dung de test hom nay) — cung mot khoang thoi gian, it core hon
    -- ro rang cho ket qua kem hon (da kiem chung that: RunID 1265 tren Docker 600s/4-core con 23
    -- dong chua xep duoc, trong khi local 300s/8-core chi con 2 dong). Nang tran de bu lai phan
    -- thieu hut phan cung, danh rieng cho Round 1.5 (round quan trong nhat, dang chi xin 700s qua
    -- module.json UI nhung bi tran cu 600s chan bot) — cac round khac (Round 2/4) hien khong xin
    -- qua 600s nen khong bi anh huong boi viec nang tran nay.
    IF @MaxSecs > 1200 SET @MaxSecs = 1200;

    -- ENG1/TANN/SU (nhieu GV KHAC NHAU cung day 1 lop cung mon, LUAN PHIEN thay nhau theo tuan —
    -- xac nhan voi nguoi dung 2026-08-22, ke ca truong hop 2 GV trung ten thuc su la 2 nguoi khac
    -- nhau vd 2x "Tran Thanh Hien" o mon SU). KHONG PHAI moi GV deu day dong thoi hang tuan.
    -- Voi Auto chi lay 1 dong dai dien/lop (slot co dinh trong TKB mau), GV cu the truc tuan nao
    -- do quan ly rieng ngoai pham vi TKB template.
    --
    -- R17 (2026-08-24): neu @RunIDDangXay duoc truyen, day la 1 "phien TKB dang xay" da co san
    -- mot so dong DA KHOA TAY (Buoc 1-5, chen qua spAPI_TkbKetQuaXepChenKhoa) — NhuCau chi lay
    -- phan CHUA CO trong tblTKB_KetQuaXep cua phien do, tranh xep trung/thua len phan da khoa.
    --
    -- R18 (2026-08-24): @TuanHienTai loc PCGD theo TuanApDungTu/Den (giai doan dai, vd KHTN 8-9,
    -- Ly/Hoa/Sinh moc tuan 21) va ApDungTuanChan (chan/le, vd LS-DL). Khong truyen @TuanHienTai
    -- (NULL) = giu nguyen hanh vi cu, lay tat ca (khong loc theo tuan).
    -- SUA 2026-09-17 (theo de xuat nguoi dung "Xep GV Tieu hoc co do khan hiem khong" — phat hien qua
    -- 28 GV khoi 1-5 bi "TrungLichCoDinh" that su, doi chieu voi tblTKB_ThucTe_ChiTiet (lich sap tay
    -- that) xac nhan VAN CO loi giai kha thi, chi la Round 2 xu ly GV do TRE hon dang le): GVDiem
    -- (duoi day) truoc gio CHI tru "slot GVCamTuyetDoi" (lich ban ca nhan) khoi 45 slot chuan, HOAN
    -- TOAN KHONG biet gi ve lich hop TO CO DINH (tblTKB_LichHopCoDinh, vd "01-HOP"/"KT-HOP" — GVCN/
    -- khoi truong hop rat nhieu) — vi day la nguon du lieu RIENG, chi duoc gop vao rang buoc cung
    -- (@GVBanCoDinhJson) o RAT XA phia duoi file nay (sau khi NhuCauJson/GVDiem da tinh xong). Ket
    -- qua: GV hop nhieu (dac biet GVCN/khoi truong Tieu hoc) bi DoKhanHiem tinh CAO HON that (trong
    -- ve con nhieu gio ranh hon thuc te), Round 2 xu ly ho tre, den luc do slot ranh THAT (sau khi
    -- tru dung gio hop) da het sach. Tinh truoc @tmpGVHop (GV -> tap slot hop co dinh, DUNG LAI y het
    -- logic GVNhom/Expanded o duoi — anh xa GV->To qua PhongBanChucVu, hoac GVCN khoi Tieu hoc) de
    -- GVDiem phia duoi tru dung, KHONG doi logic rang buoc cung @GVBanCoDinhJson (van giu nguyen o
    -- duoi, tranh rui ro dung vao phan dang chay dung).
    DECLARE @tmpGVHop TABLE (MaGV VARCHAR(9), Thu INT, Buoi VARCHAR(10), Tiet INT, PRIMARY KEY (MaGV, Thu, Buoi, Tiet));
    -- 2026-10-07: lich hop doc tu dbo.fnTkbLichHopGV(@TuanHienTai) — co lich hop that rieng tuan
    -- (tblTKB_LichHopGV_Tuan) thi dung, khong thi lich hop co dinh nhu cu (logic GVNhom chuyen vao ham).
    INSERT INTO @tmpGVHop (MaGV, Thu, Buoi, Tiet)
    SELECT DISTINCT h.MaGV, h.Thu, h.Buoi, h.Tiet
    FROM dbo.fnTkbLichHopGV(@TuanHienTai) h
    WHERE h.Tiet <= 5;

    DECLARE @NhuCauJson NVARCHAR(MAX);
    ;WITH PCGDLoc AS (
        SELECT pc.*, l.Khoi, ISNULL(daKhoa.SoTietDaXep, 0) AS SoTietDaXep,
               ROW_NUMBER() OVER (PARTITION BY pc.MaLop, pc.MaMon, pc.HocKy
                   ORDER BY CASE WHEN pc.MaMon IN ('ENG1','TANN','SU') THEN pc.PhanCongID END) AS rn
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        -- FIX (2026-09-13, phat hien qua pilot test "va cuc bo" GV NV0000745): ban cu loai tru theo
        -- kieu co/khong (EXISTS bat ky dong nao trong tblTKB_KetQuaXep la coi nhu "xong het", loai
        -- HOAN TOAN khoi NhuCau) — sai voi truong hop XEP DUOC MOT PHAN (vd GV da xep 2/6 tiet ENG2,
        -- con thieu 4 tiet theo tblTKB_ChayAutoKhongXepDuoc), vi chi can CO 1 dong da xep la ca combo
        -- (Lop,Mon,GV) bi loai vinh vien khoi NhuCau, solver khong bao gio duoc thay 4 tiet con thieu
        -- do de thu giai lai (chan dung ky thuat "vá cục bộ" — @ChiGV tra ve "KhongCoNhuCau" gia).
        -- Sua: dem SO TIET DA XEP THAT (COUNT thay vi EXISTS), chi loai HOAN TOAN khoi NhuCau khi
        -- SoTietDaXep >= dinh muc (SoTietChuanTuan) — con thieu bao nhieu thi gui dung bay nhieu
        -- xuong solver (xem SoTiet o SELECT @NhuCauJson ben duoi, tru them SoTietDaXep).
        OUTER APPLY (
            SELECT COUNT(*) AS SoTietDaXep
            FROM tblTKB_KetQuaXep k
            WHERE @RunIDDangXay IS NOT NULL AND k.RunID = @RunIDDangXay
              AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV
        ) daKhoa
        WHERE pc.Enable = 1
          -- @Khoi ho tro nhieu khoi cach nhau boi dau phay (vd '06,07') de gop nhieu khoi trong 1 lan chay Auto,
          -- van dam bao 1 GV day nhieu khoi trong mo hinh khong bi xep trung giua cac khoi do.
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND ISNULL(daKhoa.SoTietDaXep, 0) < pc.SoTietChuanTuan
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          -- @ChiGV (2026-09-12, theo de xuat nguoi dung "xep nguoi that": Round 2 phai xep TUNG GV mot
          -- theo do khan hiem, rai HET cac lop cua GV do bat ke khoi, roi khoa ngay truoc khi sang GV
          -- ke tiep) — khi truyen, NhuCau CHI gom dung 1 GV nay, moi PCGD khac giu nguyen cho vong sau.
          AND (@ChiGV IS NULL OR pc.MaGV = @ChiGV)
          -- @ChiLop (2026-09-18, theo dung nguyen tac da chung minh dung voi @ChiGV o Round 3/5/6/7 —
          -- xem spAPI_TkbGiaiLopThuongTuanTu de biet ly do day du: mon thuong (TOAN/VAN...) canh tranh
          -- cho o LOP (nhieu mon/nhieu GV khac nhau cung tranh slot cua 1 LOP), khong phai o GV nhu tiet
          -- doi — nen don vi giai tuan tu dung phai la LOP, khong phai GV): khi truyen, NhuCau CHI gom
          -- dung 1 LOP nay, moi PCGD lop khac giu nguyen cho vong sau. Ho tro nhieu lop cach nhau dau
          -- phay giong @Khoi (hien tai luon truyen 1 lop/lan tu dong giai tuan tu, nhung de mo cho linh
          -- hoat).
          AND (@ChiLop IS NULL OR @ChiLop = '' OR pc.MaLop IN (SELECT value FROM STRING_SPLIT(@ChiLop, ',')))
          -- @ChiMon (2026-09-19): CHI giai cac mon nay (danh sach MaMon cach nhau dau phay) — dung cho buoc xep TOAN
          -- tieu hoc SOM (spAPI_TkbRound6_TietDoiCap1) de mon chinh chiem gio dep truoc mon phu.
          AND (@ChiMon IS NULL OR @ChiMon = '' OR pc.MaMon IN (SELECT value FROM STRING_SPLIT(@ChiMon, ','))
               OR (@ThemGV IS NOT NULL AND pc.MaGV IN (SELECT value FROM STRING_SPLIT(@ThemGV, ','))))
          -- SUA 2026-09-14 (theo phan bien nguoi dung — "TV cung co tiet doi, sao lai hard-code chi
          -- theo BatBuocXepDoi"): @ChiMonDoi ban dau CHI loc theo co BatBuocXepDoi=1 (AI/BOI/ENG1/ENG2/
          -- GDQP/STEM/TANN/TAVN) — bo sot TV (Tieng Viet Tieu hoc), mon nay KHONG co co BatBuocXepDoi
          -- (vi KHONG PHAI "luon luon doi" don gian, ma la PATTERN rieng biet moi khoi qua tblTKB_
          -- MonQuyTac — vd TV_Khoi45_Pattern "Thu2-3-4 mau doi-le-doi", TV_Khoi3_Pattern "Thu6 bat
          -- buoc co tiet doi"). Kiem chung thuc te (RunID 1269 shadow test): dua TV vao giai GOP cung
          -- 8 mon tiet doi con lai -> tu 14 nhom/34 tiet ket xuong 0/0 (100%) — CHUNG MINH TV bi cung
          -- 1 loai loi "phan manh slot do Round 2 chiem truoc" nhu AI/BOI/ENG/STEM. Sua: @ChiMonDoi mo
          -- rong gom THEM moi MaMon co rang buoc PATTERN cung (tblTKB_MonQuyTac, LoaiQuyTac dang '%_
          -- Pattern', TRU HDTN1_Pattern vi HDTN1 da xu ly rieng o Round 1, khong lien quan Round 1.6).
          AND (@ChiMonDoi = 0 OR (@ThemGV IS NOT NULL AND pc.MaGV IN (SELECT value FROM STRING_SPLIT(@ThemGV, ','))) OR EXISTS (
              SELECT 1 FROM tblTKB_MonHoc mh WHERE mh.MaMon = pc.MaMon AND mh.BatBuocXepDoi = 1
          ) OR EXISTS (
              SELECT 1 FROM tblTKB_MonQuyTac mq WHERE mq.MaMon = pc.MaMon AND mq.Enable = 1
                AND mq.LoaiQuyTac LIKE '%_Pattern' AND mq.LoaiQuyTac <> 'HDTN1_Pattern'
          ))
          AND (
              @ChiCumTach = 0
              OR (@ChiCumTach = 1 AND EXISTS (
                  SELECT 1 FROM tblTKB_CumTach_NhomCon ctn6
                  INNER JOIN tblTKB_CumTach ct6 ON ct6.ID = ctn6.CumTachID AND ct6.Enable = 1
                  WHERE ctn6.MaLop = pc.MaLop
              ))
              OR (@ChiCumTach = 2 AND NOT EXISTS (
                  SELECT 1 FROM tblTKB_CumTach_NhomCon ctn6
                  INNER JOIN tblTKB_CumTach ct6 ON ct6.ID = ctn6.CumTachID AND ct6.Enable = 1
                  WHERE ctn6.MaLop = pc.MaLop
              ))
          )
    ),
    -- Gop chung 1 mach WITH voi PCGDLoc (SQL Server khong cho phep noi tiep 2 ";WITH" rieng cho cung
    -- 1 statement) — CTE nay xac dinh cac Khoi da co "sinh hoat tap trung/chao co" resolve cho @TuanHienTai,
    -- dung de tinh SoTiet HDTN1 con lai (xem SELECT @NhuCauJson ben duoi).
    -- SUA 2026-09-21 (theo dinh chinh nguoi dung): tiet "sinh hoat tap trung/chao co" theo khoi KHONG
    -- lap lai moi tuan — CHI tuan nao co lich rieng trong tblTKB_ChaoCoKhoi_Tuan moi gan. Bo han
    -- fallback ve tblTKB_ChaoCoKhoi (bang co dinh "dau thang") — truoc day fallback khien HDTN1 cua
    -- MOI tuan bi khoa cung o 1 gio co dinh, sai voi thuc te (tuan khong co sinh hoat chung thi HDTN1
    -- xep tu do, chi rieng tiet Thu6 cuoi ngay la bat buoc).
    ChaoCoResolvedKhoi AS (
        SELECT DISTINCT cct.Khoi FROM tblTKB_ChaoCoKhoi_Tuan cct WHERE cct.Enable = 1 AND cct.Tuan = @TuanHienTai
    ),
    -- GVDiem (2026-09-12, theo de xuat nguoi dung "tư duy đệ quy — ưu tiên ai trước ai sau ngay trong
    -- 1 round nhỏ"): diem khan hiem moi GV, CUNG CONG THUC voi Round 2 (spAPI_TkbXepDoKhanHiem) —
    -- (45 - so slot da ban trong RunID nay - so slot GVCamTuyetDoi) / tong so tiet GV do can day (toan
    -- bo PCGD, khong gioi han @Khoi/@ChiGV — phan anh dung do khan hiem THAT cua GV, khong chi trong
    -- pham vi dang giai). CHI tinh duoc khi co @RunIDDangXay (biet lay "da ban" tu dau) — NULL neu
    -- khong co (RunID hoan toan moi), solver se tu dung mac dinh 5000 flat nhu cu.
    -- SUA 2026-09-13 (phat hien qua so sanh thuc te RunID 1260 vs 1263 — GV Hoang Thanh Quang
    -- NV0000745, day 8 lop/2 khoi, bi cong thuc cu xep NGANG HANG voi 1 GV day 1 lop duy nhat cung
    -- tong tiet, ca 2 deu bi kep ve san 1.0 = trong so thap nhat, du day nhieu khoi kho hon han ve
    -- mat rang buoc dong bo R23 doc lap tung khoi): them chia cho SoKhoi (so khoi KHAC NHAU GV do
    -- day, tinh tu tblTKB_Lop.Khoi qua PCGD) — day nhieu khoi hon thi DoKhanHiem giam (khan hiem hon,
    -- duoc bao ve cao hon), phan anh dung rang buoc that (moi khoi la 1 "ban co" dong bo doc lap phai
    -- xep dong thoi, khong chi la "nhieu tiet hon" don thuan).
    GVDiem AS (
        -- FIX (2026-09-13, phat hien qua cau hoi thuc te "sao ra tren 38 tiet/tuan dc" — GV day
        -- AI/STEM co nhieu dong PCGD cho CUNG 1 lop nhung khac TuanApDungTu/Den, vd tuan 23, 28-31,
        -- 37-40, 46-49 — day la "xoay vong theo giai doan" (R18), KHONG PHAI cong don cung luc. Ban
        -- cu SUM(SoTietChuanTuan) khong loc theo @TuanHienTai (khac voi PCGDLoc da loc dung), khien
        -- TongCan ao rat lon (vd 241, 130, 126 tiet/tuan — vo ly ve mat vat ly, toi da 45) cho GV day
        -- cac mon xoay vong nhu vay, lam DoKhanHiem sai lech nghiem trong. Sua: ap dung DUNG bo loc
        -- tuan (@TuanHienTai/TuanApDungTu/Den/ApDungTuanChan) GIONG HET PCGDLoc, chi tinh trung "phan
        -- PCGD that su hieu luc trong tuan dang giai" — dung ban chat cau hoi (workload THAT trong
        -- tuan nay, khong phai tong ca nam).
        -- SUA 2026-09-13 (theo de xuat nguoi dung, kiem chung bang du lieu that — 11 GV co TOI 100%
        -- khoi luong la tiet doi, vd Hoang Thanh Quang/Julie Ocden/Nicholas Santucci...): them he so
        -- theo TY LE TIET DOI (SoTietChuanTuan cua mon co BatBuocXepDoi=1 / TongCan) — GV cang nhieu
        -- tiet doi cang kho xep (tiet doi can DUNG 2 slot lien tiep cung luc, khong the chen linh
        -- hoat vao 1 o trong le nhu tiet don), nen chia them (1 + TyLeTietDoi) vao mau so: ty le 100%
        -- (nhu Hoang Thanh Quang) lam DoKhanHiem giam mot nua (kho hon gap doi so voi toan tiet don).
        -- SUA 2026-09-16 (theo de xuat nguoi dung "co Mai Khanh do khan hiem chua tinh lich ban" —
        -- kiem chung bang du lieu that: co day CDHTLy trong cum R23 "Phan ban chuyen de 11B" nhung
        -- ban Chieu Tiet 3-5 T2-T6 tuan 8-23 trong tblTKB_GVCamTuyetDoi_Tuan; DoKhanHiem cu CHI doc
        -- tblTKB_GVCamTuyetDoi theo RunID — bang nay THUC TE luon RONG tren toan he thong vi chi duoc
        -- ghi khi co nguoi bam "Bao ban" qua spAPI_TkbGVBaoBan_ApDung, khong tu dong sync tu _Tuan —
        -- nen moi GV co lich ban dai han (thinh giang/ban dinh ky) deu bi tinh THIEU, DoKhanHiem ra
        -- cao hon that, bao ve kem hon dang ra. Sua TONG QUAT cho MOI GV: UNION them tblTKB_GVCamTuyetDoi_Tuan
        -- loc theo @TuanHienTai, GIAN NO Buoi=''/Tiet=NULL thanh sieu tap that (Sang/Chieu x Tiet 1-5)
        -- CUNG PATTERN voi @GVCamTuyetDoiJson (rang buoc cung) o duoi da lam dung tu truoc — 2 nguon
        -- gio khop nhau, DoKhanHiem phan anh dung do khan hiem THAT cua GV thay vi chi phan RunID.
        SELECT pc3.MaGV,
               CAST((45.0
                   - (SELECT COUNT(*) FROM tblTKB_KetQuaXep k3 WHERE k3.RunID = @RunIDDangXay AND k3.MaGV = pc3.MaGV)
                   - (SELECT COUNT(DISTINCT CONCAT(Thu,'-',Buoi,'-',Tiet)) FROM (
                         SELECT Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunIDDangXay AND MaGV = pc3.MaGV
                         UNION
                         SELECT g.Thu, bb.Buoi, tt.Tiet
                         FROM tblTKB_GVCamTuyetDoi_Tuan g
                         CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
                         CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
                         WHERE g.MaGV = pc3.MaGV AND g.Tuan = @TuanHienTai
                         UNION
                         SELECT h.Thu, h.Buoi, h.Tiet FROM @tmpGVHop h WHERE h.MaGV = pc3.MaGV
                     ) camGop)
               ) / NULLIF(SUM(pc3.SoTietChuanTuan), 0)
                 / NULLIF((SELECT COUNT(DISTINCT l3.Khoi) FROM tblTKB_PhanCongGiangDay pc4
                           INNER JOIN tblTKB_Lop l3 ON l3.MaLop = pc4.MaLop
                           WHERE pc4.Enable = 1 AND pc4.MaMon <> 'SH' AND pc4.MaGV = pc3.MaGV
                             AND (@HocKy = '' OR pc4.HocKy = @HocKy)
                             AND (@TuanHienTai IS NULL OR pc4.TuanApDungTu IS NULL OR @TuanHienTai >= pc4.TuanApDungTu)
                             AND (@TuanHienTai IS NULL OR pc4.TuanApDungDen IS NULL OR @TuanHienTai <= pc4.TuanApDungDen)
                             AND (@TuanHienTai IS NULL OR pc4.ApDungTuanChan IS NULL OR pc4.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)), 0)
                 / (1.0 + SUM(CASE WHEN mh3.BatBuocXepDoi = 1 THEN pc3.SoTietChuanTuan ELSE 0 END) / NULLIF(SUM(pc3.SoTietChuanTuan), 0))
               AS FLOAT) AS DoKhanHiem
        FROM tblTKB_PhanCongGiangDay pc3
        LEFT JOIN tblTKB_MonHoc mh3 ON mh3.MaMon = pc3.MaMon
        WHERE pc3.Enable = 1 AND pc3.MaMon <> 'SH' AND @RunIDDangXay IS NOT NULL
          -- SUA 2026-09-13: them loc @HocKy (GV co the co PCGD rieng cho CA HK1 va HK2 cung 1 lop/mon
          -- — luan phien theo hoc ky, khong phai cong don) — thieu dieu kien nay la nguon "tien" con
          -- lai gay TongCan ao (vd Le Thanh Dien 68 -> con qua 38, du da loc tuan) sau khi sua tuan.
          AND (@HocKy = '' OR pc3.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc3.TuanApDungTu IS NULL OR @TuanHienTai >= pc3.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc3.TuanApDungDen IS NULL OR @TuanHienTai <= pc3.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc3.ApDungTuanChan IS NULL OR pc3.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc3.MaGV
    )
    -- KIEN TRUC MOI (2026-08-30, theo de xuat nguoi dung): SH (Sinh hoat chu nhiem cap 2-3) xu ly
    -- nhu lich hop co dinh — KHOA CUNG truc tiep vao tblTKB_KetQuaXep NGAY TU DAU (xem doan sau, sau
    -- khi @RunID duoc xac dinh), KHONG con la 1 don vi de CP-SAT tu quyet dinh vi tri nua. Loai han
    -- SH khoi @NhuCauJson (khong chi khi co @RunIDDangXay) de solver khong bao gio "thay" SH — tranh
    -- dut khoat cac loi da gap nhieu lan (SH bi solver "skip" do het thoi gian tim kiem, hoac mon
    -- khac chiem mat gio SH khi rang buoc mem/hard trong code C# khong du manh).
    -- ⚠️ SUA 2026-09-12: khi dang xu ly rieng 1 GV (@ChiGV, Round 2) MA GV do lam GVCN (co dong SH),
    -- KHONG con loai SH khoi NhuCau mu quang nua — chi loai neu slot mac dinh/override THAT SU con
    -- ranh cho GV do (kiem tra truc tiep tblTKB_KetQuaXep cua @RunIDDangXay); neu GV da ban dung slot
    -- do (day cheo khoi/cap), SH roi vao NhuCau de CP-SAT tu tim cho khac — xem nhanh @ChiGV o doan
    -- auto-khoa SH phia duoi, PHAI dong bo dung 1 dieu kien voi doan nay de tranh chen trung 2 lan.
    -- HDTN1 (GVCN) tai khoi co "sinh hoat tap trung/chao co" da resolve cho @TuanHienTai (2026-09-12,
    -- theo phan bien nguoi dung: "lich do la uu tien khong thuong luong duoc thi day qua CP-SAT lam
    -- gi" — dung, truoc day chi CHAN mon khac (R22) chu KHONG khoa dung don vi HDTN1 that, khien no
    -- van troi noi tu do cho CP-SAT tu xep o cho khac, vua sai thuc te vua lang phi khong gian tim
    -- kiem). Loai 1 DON VI HDTN1 khoi NhuCau NEU khoi cua no co 1 slot chao co da resolve (uu tien
    -- tblTKB_ChaoCoKhoi_Tuan theo @TuanHienTai, fallback tblTKB_ChaoCoKhoi) — don vi nay se duoc khoa
    -- cung truc tiep vao tblTKB_KetQuaXep o doan sau (cung cong thuc voi SH), giong het kien truc SH.
    -- SUA 2026-09-12 (bug phat hien qua phan anh nguoi dung "HDTN1 tieu hoc khong dung"): cap 2-3 co
    -- SoTietChuanTuan=1 (dung het = 1 tiet chao co, loai CA DONG la dung) nhung Tieu hoc (01-05) co
    -- SoTietChuanTuan=3 (1 chao co Thu3 + 1 linh hoat Thu2/4/5 + 1 cuoi ngay Thu6, xem TkbCpSatSolver.cs
    -- rule 7b) — loai CA DONG nhu truoc day khien 2 tiet con lai (linh hoat + Thu6) BIEN MAT HOAN TOAN,
    -- khong bao gio duoc gui cho solver. Sua: CHI TRU 1 (so voi SoTietChuanTuan), KHONG loai ca dong,
    -- tru khi tru xong <= 0 (truong hop cap 2-3, giu nguyen hanh vi loai ca dong nhu cu).
    -- MO RONG 2026-09-12 (theo de xuat nguoi dung "gan mac dinh, chi GV doi lich dac thu moi sua tay"):
    -- tiet cuoi ngay Thu6 CUNG duoc khoa cung MAC DINH ben ngoai (xem doan INSERT phia duoi, dung cong
    -- thuc mac dinh+override voi tblTKB_HDTN1_OverrideSlot y het SH) — CHI ap dung khi SoTietChuanTuan>1
    -- (nghia la Tieu hoc, khac cap 2-3 chi co dung 1 tiet/tuan da dung het cho chao co, khong con Thu6
    -- rieng). Vay tru THEM 1 nua (tong 2: chao co + Thu6) khoi NhuCau khi dieu kien nay dung.
    SELECT @NhuCauJson = (
        SELECT p.MaLop, p.MaMon, p.MaGV,
               CASE WHEN p.MaMon = 'HDTN1' THEN
                   -- SUA 2026-09-21: cap 2-3 (SoTietChuanTuan=1) chi co 1 tiet HDTN1 = tiet sinh hoat tap
                   -- trung; tuan co lich (ccr) thi da khoa cung ben ngoai, tuan KHONG co lich thi KHONG co
                   -- tiet nay (khong gui xuong solver) => luon 0. Tieu hoc (3 tiet): tru chao co (neu co)
                   -- va tiet Thu6 cuoi ngay, con lai tu do.
                   -- SUA 2026-09-25 (nguyen nhan 03E/05A co 4 tiet HDTN1 thay vi 3, chiem mat 1 o cua lop): cong thuc cu LUON tru dung
                   -- (chao co + Thu6) = 2 tiet tu do, KHONG tinh tiet da xep — lan goi sau (R7/R9/...) khi lop moi xep 2/3 tiet
                   -- (Thu6 + 1 tu do) lai xin them 2 tiet nua -> tong 4. Nay tru MAX(tiet da xep, so tiet khoa san = chao co + Thu6).
                   CASE WHEN p.SoTietChuanTuan > 1
                        THEN CASE WHEN p.SoTietChuanTuan
                                       - (CASE WHEN p.SoTietDaXep > (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1
                                               THEN p.SoTietDaXep
                                               ELSE (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1 END) < 0
                                  THEN 0
                                  ELSE p.SoTietChuanTuan
                                       - (CASE WHEN p.SoTietDaXep > (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1
                                               THEN p.SoTietDaXep
                                               ELSE (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1 END) END
                        ELSE 0 END
               -- SUA 2026-09-13: tru them SoTietDaXep (thay vi gui nguyen SoTietChuanTuan) — dung
               -- cho truong hop XEP DUOC MOT PHAN (xem giai thich tai PCGDLoc/OUTER APPLY daKhoa
               -- o tren), tranh gui thua tiet da co san hoac lam solver tuong lai dinh muc >
               -- SoTietChuanTuan that.
               ELSE p.SoTietChuanTuan - p.SoTietDaXep END AS SoTiet,
               gd.DoKhanHiem,
               -- SUA 2026-09-13 (theo de xuat nguoi dung — "bang 1" (DoKhanHiem theo GV) va "bang 2"
               -- (tiet doi theo Lop) do 2 THUOC TINH khac nhau: cai kho nam o CHINH CAI LOP (thuoc cum
               -- dong bo R23) chu khong phai o GV day lop do. 1 GV bat ky duoc phan cong day 1 lop
               -- trong cum tach van phai chiu dung do kho cua cum, bat ke GV do ban ron hay khong.
               -- SUA 2026-09-13 (phat hien qua mo phong truoc khi deploy — TAT CA 263/263 dong deu ra
               -- LaCumTach=true, ke ca TOAN/VAN/LY cua lop thuong 10A/11B/12C): ban dau kiem tra CA
               -- NhomCon LAN LopNguon, nhung du lieu that cho thay MOI lop THAT trong khoi 10-12 (10A,
               -- 10B... 12E) DEU la "Lop nguon" cua cum AV (ca khoi tach AV+Tin) — nen dieu kien
               -- LopNguon lam flag=true TRAN LAN cho toan bo khoi, mat het kha nang phan biet (TOAN/VAN/
               -- LY cua lop thuong khong lien quan gi den dong bo R23 nhung van bi tinh nham). Chi
               -- NhomCon (lop AO thuc su bi tach, vd 10AV1-6/10A1/10A2/10F1/10F2) moi dung la don vi
               -- can dong bo — bo han dieu kien LopNguon.
               CAST(CASE WHEN EXISTS (
                   SELECT 1 FROM tblTKB_CumTach_NhomCon ctn
                   INNER JOIN tblTKB_CumTach ct1 ON ct1.ID = ctn.CumTachID AND ct1.Enable = 1
                   WHERE ctn.MaLop = p.MaLop
               ) THEN 1 ELSE 0 END AS BIT) AS LaCumTach
        FROM PCGDLoc p
        LEFT JOIN ChaoCoResolvedKhoi ccr ON ccr.Khoi = p.Khoi
        LEFT JOIN GVDiem gd ON gd.MaGV = p.MaGV
        -- 2026-10-07: dong PCGD RIENG 1 tuan (TuanApDungTu = TuanApDungDen, chuan hoa tu lich that) duoc giu het —
        -- vd 01GTG TANN tuan 11 co 2 GV that day chung (2+2 tiet); chong trung chi ap cho dong chung nhieu tuan.
        WHERE (p.MaMon NOT IN ('ENG1', 'TANN', 'SU') OR p.rn = 1 OR (p.TuanApDungTu IS NOT NULL AND p.TuanApDungTu = p.TuanApDungDen))
          AND (
              p.MaMon <> 'SH'
              OR (
                  @ChiGV IS NOT NULL AND p.MaGV = @ChiGV
                  AND EXISTS (
                      SELECT 1 FROM tblTKB_KetQuaXep k2
                      WHERE k2.RunID = @RunIDDangXay AND k2.MaGV = p.MaGV
                        AND k2.Thu = ISNULL((SELECT ov.Thu FROM tblTKB_SH_OverrideSlot ov WHERE ov.MaLop = p.MaLop AND ov.Enable = 1), 6)
                        AND k2.Buoi = ISNULL((SELECT ov.Buoi FROM tblTKB_SH_OverrideSlot ov WHERE ov.MaLop = p.MaLop AND ov.Enable = 1), N'Chieu')
                        AND k2.Tiet = ISNULL((SELECT ov.Tiet FROM tblTKB_SH_OverrideSlot ov WHERE ov.MaLop = p.MaLop AND ov.Enable = 1), 4)
                  )
              )
          )
          AND (
              p.MaMon <> 'HDTN1'
              OR (
                  CASE WHEN p.SoTietChuanTuan > 1
                       THEN p.SoTietChuanTuan
                            - (CASE WHEN p.SoTietDaXep > (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1
                                    THEN p.SoTietDaXep
                                    ELSE (CASE WHEN ccr.Khoi IS NOT NULL THEN 1 ELSE 0 END) + 1 END)
                       ELSE 0 END
              ) > 0
          )
        FOR JSON PATH
    );

    IF @NhuCauJson IS NULL OR @NhuCauJson = '[]'
    BEGIN
        IF @ChiCapNhat = 0
        BEGIN
        SELECT 0 AS RunID, N'KhongCoNhuCau' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               N'Không có phân công giảng dạy nào phù hợp để xếp lịch' AS ThongBao;
        END
        RETURN;
    END

    DECLARE @MonBatBuocXepDoiJson NVARCHAR(MAX) = '[' + ISNULL((
        SELECT STRING_AGG('"' + REPLACE(MaMon, '"', '\"') + '"', ',')
        FROM tblTKB_MonHoc WHERE BatBuocXepDoi = 1
    ), '') + ']';

    -- GV ban co dinh: hop to (theo PhongBanChucVu) + hop khoi tieu hoc 1-5 (theo PCGD/Lop.Khoi) + hop khoi truong.
    -- Chi lay Tiet<=5 vi solver chi mo hinh hoa Tiet 1..5/buoi (cac lich hop luc Tiet 8-9 la ngoai gio ban tru,
    -- nam ngoai pham vi mo hinh nen khong the ep buoc o day).
    DECLARE @GVBanCoDinhJson NVARCHAR(MAX);
    -- GV thinh giang (2026-09-11, theo de xuat nguoi dung): khong thuoc bien che nen KHONG du hop To
    -- chuyen mon (nhung van du hop Khoi/GVCN neu co) — loai khoi TAT CA nhanh LoaiNhom='To' duoi day
    -- de tang tiet trong that su cho GV thinh giang (thuong nang luc bi han che boi lich day + hop).
    -- 2026-10-07: GVNhom + Expanded chuyen vao dbo.fnTkbLichHopGV (dung chung voi spAPI_TkbChayAutoTrangThai,
    -- ho tro lich hop that rieng tung tuan qua tblTKB_LichHopGV_Tuan). Cung = hop khoi tieu hoc (GVCN).
    ;WITH Expanded AS (
        SELECT h.MaGV, h.Thu, h.Buoi, h.Tiet, MAX(h.Cung) AS Cung
        FROM dbo.fnTkbLichHopGV(@TuanHienTai) h
        GROUP BY h.MaGV, h.Thu, h.Buoi, h.Tiet
    )
    SELECT @GVBanCoDinhJson = (
        SELECT MaGV, Thu, Buoi, Tiet, CAST(Cung AS BIT) AS Cung FROM Expanded WHERE Tiet <= 5 FOR JSON PATH
    );
    IF @GVBanCoDinhJson IS NULL SET @GVBanCoDinhJson = '[]';

    -- 2026-10-07 (phan tich 162 tiet thieu T8-T11): o GVCN TIEU HOC ban (hop theo tuan + bao ban) chi GV CHUYEN day duoc.
    -- Gui solver de phat neu lop de trong o do (nguoi xep tay lap kin 192/192 o, may de trong 95/843 -> mon GVCN het cho).
    DECLARE @OChuyenJson NVARCHAR(MAX) = (
        SELECT DISTINCT l.MaLop, b.Thu, b.Buoi, b.Tiet, 2000 AS Phat
        FROM tblTKB_Lop l
        CROSS APPLY (
            SELECT h.Thu, h.Buoi, h.Tiet FROM dbo.fnTkbLichHopGV(@TuanHienTai) h
            WHERE h.MaGV = l.GVCN AND h.LoaiNhom <> 'KhoiCap23SH' AND h.Tiet <= 4
            UNION
            SELECT g.Thu, bb.Buoi, tt.Tiet FROM tblTKB_GVCamTuyetDoi_Tuan g
            CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(g.Buoi,'') = '' OR g.Buoi = x.Buoi) bb
            CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
            WHERE g.Tuan = @TuanHienTai AND g.MaGV = l.GVCN
        ) b
        WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND ISNULL(l.GVCN, '') <> ''
          AND LEN(l.MaLop) = 3   -- chi lop chinh quy (bo lop tang cuong TA 01xTG — chi hoc 10 tiet TA, trong la binh thuong)
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
        FOR JSON PATH
    );
    IF @OChuyenJson IS NULL SET @OChuyenJson = '[]';

    -- R1 (2026-08-24): PhongPoolTheoMon (chon phong cu the cho mon dung phong dac thu, vd Boi/Nhac)
    -- va KhoaPhongDungChung (khoa toan bo 1 khung gio cho pool phong, R1.2/1.6) — truoc day CHUA
    -- TUNG duoc gui len solver (tham so luon rong).
    -- Anh xa LoaiKhoa(tien to ten phong, vd 'BOI'/'AN') -> PoolTag(khoa trong PhongPoolTheoMon, vd
    -- 'BOI'/'NHAC') la hard-code co chu dich (2 quy uoc dat ten khac nhau, khong lien quan Cap hoc),
    -- giu nguyen khi them BOI/NHAC moi. Con viec loc dung Tiet theo Tieu hoc/THCS-THPT (R1.6, cung
    -- 1 khung gio thuc nhung khac Tiet giua 2 cap) da duoc xu ly TRUOC do, ngay luc chen vao
    -- tblTKB_KetQuaXep qua spAPI_TkbKhoaPhongDungChungApDung (dung cot MaCap) — nen khi doc lai o day
    -- theo dung @RunIDDangXay, du lieu da san sung dung cap, khong can loc lai MaCap lan nua.
    -- Nhom phong dac thu (2026-10-09): STEM THCS chi 1 phong E102 (STEAM1); STEM THPT 3 phong thi nghiem;
    -- AI tieu hoc chi A0 (AI1), AI THCS chi E403 (AI2); Tieng Anh khoi 1 (tru lop TG) 2 phong TA1/TA2.
    IF OBJECT_ID('tempdb..#PoolLop') IS NOT NULL DROP TABLE #PoolLop;
    ;WITH PoolDef AS (
        SELECT * FROM (VALUES
            ('STEM', '06,07,08,09', 0, 'STEAM1'),
            ('STEM', '10,11,12', 0, 'LI,HOA,SINH'),
            ('AI', '01,02,03,04,05', 1, 'AI1'),
            ('AI', '06,07,08,09', 0, 'AI2'),
            ('TANN', '01', 1, 'TA1,TA2'),
            ('TAVN', '01', 1, 'TA1,TA2')
        ) v(MaMon, Khois, ChiLopChinh, Phongs)
    )
    SELECT d.MaMon, l.MaLop, d.Phongs AS PhongCsv,
           (SELECT STRING_AGG('"' + ph.MaPhong + '"', ',') FROM tblTKB_PhongHoc ph
             WHERE ph.Enable = 1 AND ph.MaPhong IN (SELECT LTRIM(value) FROM STRING_SPLIT(d.Phongs, ','))) AS Phongs,
           (SELECT COUNT(*) FROM tblTKB_PhongHoc ph
             WHERE ph.Enable = 1 AND ph.MaPhong IN (SELECT LTRIM(value) FROM STRING_SPLIT(d.Phongs, ','))) AS SoPhong
    INTO #PoolLop
    FROM PoolDef d
    INNER JOIN tblTKB_Lop l ON l.Enable = 1 AND LEFT(l.MaLop, 2) IN (SELECT value FROM STRING_SPLIT(d.Khois, ','))
    WHERE (d.ChiLopChinh = 0 OR LEN(l.MaLop) = 3)
      AND NOT EXISTS (SELECT 1 FROM tblTKB_PhongLopMon f WHERE f.Enable = 1 AND f.MaLop = l.MaLop AND f.MaMon = d.MaMon);
    -- 2026-10-09: phong CO DINH theo lop-mon (tblTKB_PhongLopMon, rut tu TKB that: moi lop hoc 1 mon luon o 1 phong)
    -- uu tien hon nhom phong o tren — moi phong 1 lop/tiet, ke ca qua nhieu buoc xep (khoa theo dung phong cu the,
    -- truoc day pool Am nhac chi biet "da du 3 phong chua" nen buoc sau van xep trung AN3).
    -- 2026-10-10 (doi chieu TKB that T8-T10): phong NHAC di theo GIAO VIEN (3 GV -> AN1/AN2/AN3, 78-94% so tiet), khong theo lop —
    -- lop doi GV Nhac (tuan 10: 07H -> thay Ngoc Hieu dung AN3) thi phong co dinh theo lop bi sai (RunID 1589: 07H o AN2 chan 05F).
    -- tblTKB_PhongGiaoVien (MaGV, MaMon, MaPhong): neu GV dang day lop-mon tuan nay co phong rieng thi dung phong do.
    ;WITH GVPhong AS (
        SELECT pc.MaLop, pc.MaMon, MIN(pg.MaPhong) AS MaPhong
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_PhongGiaoVien pg ON pg.MaGV = pc.MaGV AND pg.MaMon = pc.MaMon AND pg.Enable = 1
        WHERE pc.Enable = 1 AND pc.SoTietChuanTuan > 0 AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    ), PhongCuoi AS (
        SELECT f.MaMon, f.MaLop, COALESCE(g.MaPhong, f.MaPhong) AS MaPhong
        FROM tblTKB_PhongLopMon f LEFT JOIN GVPhong g ON g.MaLop = f.MaLop AND g.MaMon = f.MaMon
        WHERE f.Enable = 1
        UNION ALL
        SELECT g.MaMon, g.MaLop, g.MaPhong FROM GVPhong g
        WHERE NOT EXISTS (SELECT 1 FROM tblTKB_PhongLopMon f WHERE f.Enable = 1 AND f.MaLop = g.MaLop AND f.MaMon = g.MaMon)
    )
    INSERT #PoolLop (MaMon, MaLop, PhongCsv, Phongs, SoPhong)
    SELECT f.MaMon, f.MaLop, f.MaPhong, '"' + f.MaPhong + '"', 1
    FROM PhongCuoi f
    INNER JOIN tblTKB_PhongHoc ph ON ph.MaPhong = f.MaPhong AND ph.Enable = 1
    INNER JOIN tblTKB_Lop l ON l.MaLop = f.MaLop AND l.Enable = 1;

    DECLARE @PhongPoolTheoMonJson NVARCHAR(MAX);
    SELECT @PhongPoolTheoMonJson = '{' + STRING_AGG(CAST('"' + MaMonPool + '":[' + Phongs + ']' AS NVARCHAR(MAX)), ',') + '}'
    FROM (
        SELECT 'BOI' AS MaMonPool, STRING_AGG('"' + MaPhong + '"', ',') AS Phongs FROM tblTKB_PhongHoc WHERE MaPhong LIKE 'BOI%' AND Enable = 1
        UNION ALL
        SELECT 'NHAC', STRING_AGG('"' + MaPhong + '"', ',') FROM tblTKB_PhongHoc WHERE MaPhong LIKE 'AN%' AND Enable = 1
        -- SUA 2026-09-14 (theo de xuat nguoi dung, luat thuc te "toi da 2 lop/tiet o phong thu vien"):
        -- SHTV (Sinh hoat thu vien, Tieu hoc) dung chung 2 phong TV1/TV2 (khac TV3 = "Thu vien Trung
        -- hoc", cap khac khong lien quan) — dang truoc day KHONG co pool nao dang ky, nen CP-SAT chua
        -- tung rang buoc so luong lop dong thoi, da phat hien thuc te 2 khung gio bi xep 3 lop cung
        -- luc (RunID 1269). Dang ky giong het pattern BOI/NHAC: 2 phong trong pool = toi da 2 lop.
        UNION ALL
        SELECT 'SHTV', STRING_AGG('"' + MaPhong + '"', ',') FROM tblTKB_PhongHoc WHERE MaPhong IN ('TV1','TV2') AND Enable = 1
        -- 2026-10-09 (luat phong hoc rut tu TKB that tuan 1/8/9/10 — 0 lan 2 lop chung phong, may vi pham
        -- AI/STEM): pool theo LOP, khoa "MaMon@MaLop" (solver uu tien truoc khoa MaMon). Xem #PoolLop.
        UNION ALL
        SELECT pl.MaMon + '@' + pl.MaLop, pl.Phongs FROM #PoolLop pl
    ) x
    WHERE Phongs IS NOT NULL;
    IF @PhongPoolTheoMonJson IS NULL SET @PhongPoolTheoMonJson = '{}';

    DECLARE @KhoaPhongDungChungJson NVARCHAR(MAX) = '[]';
    IF @RunIDDangXay IS NOT NULL
    BEGIN
        ;WITH KhoaRows AS (
            SELECT DISTINCT MaLop AS LoaiKhoa, Thu, Buoi, Tiet
            FROM tblTKB_KetQuaXep
            WHERE RunID = @RunIDDangXay AND MaMon = 'KHOAPHONG'
            -- FIX (2026-09-14, phat hien qua RunID 1269 — 3 lop SHTV bi xep chung 1 khung gio, vuot
            -- qua 2 phong TV1/TV2 co san): PhongPoolTheoMon (SHTV/BOI/NHAC) CHI kiem soat dung trong
            -- CUNG 1 lan goi solver — cac lop DA duoc xep tu 1 lan goi TRUOC (vd Round 2 giai tung GV
            -- rieng le) khong co MaPhong cu the ghi lai nen lan goi SAU hoan toan khong biet pool da
            -- day. Sua: TINH THEM cac slot da "day pool" (so luong lop hien co cua MaMon nay tai dung
            -- slot >= so phong that trong pool) tu chinh tblTKB_KetQuaXep, dua vao KhoaRows CHUNG voi
            -- co che KHOAPHONG san co (PoolTag = MaMon that, khong can dich qua LoaiKhoa nhu BOI/NHAC).
            -- MO RONG 2026-09-15 (theo de xuat nguoi dung "ra them BOI/NHAC" — ban dau chi vá rieng
            -- SHTV, BOI/NHAC van con cung 1 lo hong tiem an du chua thay vi pham thuc te nao): ap dung
            -- CHUNG cho ca 3 mon dung PhongPoolTheoMon (SHTV/BOI/NHAC), moi mon tu doi chieu dung so
            -- phong that cua chinh no thay vi hard-code rieng tung mon.
            UNION ALL
            SELECT k.MaMon, k.Thu, k.Buoi, k.Tiet
            FROM tblTKB_KetQuaXep k
            INNER JOIN (
                SELECT 'SHTV' AS MaMon, COUNT(*) AS SoPhong FROM tblTKB_PhongHoc WHERE MaPhong IN ('TV1','TV2') AND Enable = 1
                UNION ALL
                SELECT 'BOI', COUNT(*) FROM tblTKB_PhongHoc WHERE MaPhong LIKE 'BOI%' AND Enable = 1
                UNION ALL
                SELECT 'NHAC', COUNT(*) FROM tblTKB_PhongHoc WHERE MaPhong LIKE 'AN%' AND Enable = 1
            ) pool ON pool.MaMon = k.MaMon
            WHERE k.RunID = @RunIDDangXay AND k.MaMon IN ('SHTV', 'BOI', 'NHAC')
            GROUP BY k.MaMon, k.Thu, k.Buoi, k.Tiet, pool.SoPhong
            HAVING COUNT(*) >= pool.SoPhong
            -- 2026-10-09: nhom phong theo lop (#PoolLop) — slot da du so phong (tinh tren cac lop cung nhom,
            -- cung bo phong) tu cac buoc xep truoc -> khoa cho MOI lop trong nhom (PoolTag = MaMon@MaLop).
            UNION ALL
            SELECT pl.MaMon + '@' + pl.MaLop, f.Thu, f.Buoi, f.Tiet
            FROM #PoolLop pl
            INNER JOIN (
                SELECT p2.PhongCsv, k.Thu, k.Buoi, k.Tiet, MAX(p2.SoPhong) AS SoPhong, COUNT(*) AS SoLop
                FROM tblTKB_KetQuaXep k
                INNER JOIN #PoolLop p2 ON p2.MaLop = k.MaLop AND p2.MaMon = k.MaMon
                WHERE k.RunID = @RunIDDangXay
                GROUP BY p2.PhongCsv, k.Thu, k.Buoi, k.Tiet
                HAVING COUNT(*) >= MAX(p2.SoPhong)
            ) f ON f.PhongCsv = pl.PhongCsv
            -- 2026-10-09: tung phong CU THE da co lop o buoc truoc (solver bo dung phong do khi chon trong nhom) —
            -- nhom 2 phong TA1/TA2 con 1 cho thi chi con 1 lop vao duoc (RunID 1527 tung xep 3 lop T6 sang).
            UNION ALL
            SELECT DISTINCT 'PHONG:' + k.MaPhong, k.Thu, k.Buoi, k.Tiet
            FROM tblTKB_KetQuaXep k
            WHERE k.RunID = @RunIDDangXay AND k.MaPhong IS NOT NULL AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'KHOAPHONG')
        )
        SELECT @KhoaPhongDungChungJson = (
            SELECT
                CASE LoaiKhoa WHEN 'BOI' THEN 'BOI' WHEN 'AN' THEN 'NHAC' ELSE LoaiKhoa END AS PoolTag,
                Thu, Tiet, Buoi
            FROM KhoaRows
            FOR JSON PATH
        );
        IF @KhoaPhongDungChungJson IS NULL SET @KhoaPhongDungChungJson = '[]';
    END

    -- R2.2 (2026-08-25): ChaoCoKhoi (khung gio chao co co dinh tung khoi, tblTKB_ChaoCoKhoi) — cung
    -- CHUA TUNG duoc gui len solver (giong het loi PhongPoolTheoMon/KhoaPhongDungChung o tren truoc
    -- khi sua) du tham so @R22BatBuoc da co san va solver da co san logic doc _chaoCoKhoi — chi la
    -- mang du lieu luon rong nen R22 khong co tac dung gi. Field JSON phai dung ten "TienToKhoi" (
    -- khop record ChaoCoDto trong Program.cs), khong phai "Khoi".
    -- 2026-09-12 (theo xac nhan nguoi dung, kem thong bao that "14/9-19/9: Sinh hoat tap trung theo
    -- khoi tai A2..." — K10/K11 tuan do doi sang Chieu, khac han tuan truoc): chao co/sinh hoat tap
    -- trung KHONG PHAI quy luat co dinh lap lai moi tuan nhu tung nghi, ma DOI THEO TUNG TUAN — them
    -- tblTKB_ChaoCoKhoi_Tuan (cung pattern voi GVCamTuyetDoi_Tuan/NgayNghi_Tuan) de ghi de rieng cho
    -- @TuanHienTai. Khoi nao co dong rieng cho dung tuan nay thi dung dong do (GHI DE, khong UNION voi
    -- dong co dinh — tranh chan nham CA 2 khung gio cung luc); khoi khac van fallback ve bang co dinh.
    DECLARE @ChaoCoKhoiJson NVARCHAR(MAX);
    -- SUA 2026-09-21: chi lay lich rieng theo tuan (khong fallback bang co dinh) — xem ChaoCoResolvedKhoi.
    SELECT @ChaoCoKhoiJson = (
        SELECT cct.Khoi AS TienToKhoi, cct.Thu, cct.Tiet, cct.Buoi
        FROM tblTKB_ChaoCoKhoi_Tuan cct
        WHERE cct.Enable = 1 AND cct.Tuan = @TuanHienTai
        FOR JSON PATH
    );
    IF @ChaoCoKhoiJson IS NULL SET @ChaoCoKhoiJson = '[]';

    -- MonQuyTac (2026-08-27): cac luat tong quat hoa duoc (MaxTietMoiNgay, MaxDoiMoiNgay, CamKhungGio)
    -- doc tu tblTKB_MonQuyTac de solver ap dung theo data thay vi hardcode danh sach mon trong code —
    -- xem TkbCpSatSolver.cs, tham so ThamSo la JSON long nen phai dung JSON_QUERY (khong escape).
    DECLARE @MonQuyTacJson NVARCHAR(MAX);
    SELECT @MonQuyTacJson = (
        SELECT q.MaMon, q.Khoi, q.LoaiQuyTac, JSON_QUERY(ISNULL(q.ThamSo, '{}')) AS ThamSo
        FROM tblTKB_MonQuyTac q
        WHERE q.Enable = 1
          -- 2026-10-07: quy tac co "tuan" trong ThamSo chi ap dung DUNG tuan do va GHI DE quy tac chung cung
          -- (MaMon, Khoi, LoaiQuyTac) — vd tuan 10 GDTC khoi 12 doi T4C3 vi T6 chieu khoi 12 nghi su kien.
          AND (
                (JSON_VALUE(q.ThamSo, '$.tuan') IS NULL AND NOT EXISTS (
                    SELECT 1 FROM tblTKB_MonQuyTac o
                    WHERE o.Enable = 1 AND o.MaMon = q.MaMon AND ISNULL(o.Khoi, '') = ISNULL(q.Khoi, '')
                      AND o.LoaiQuyTac = q.LoaiQuyTac AND JSON_VALUE(o.ThamSo, '$.tuan') = CAST(@TuanHienTai AS VARCHAR(5))))
             OR JSON_VALUE(q.ThamSo, '$.tuan') = CAST(@TuanHienTai AS VARCHAR(5))
          )
        FOR JSON PATH
    );
    IF @MonQuyTacJson IS NULL SET @MonQuyTacJson = '[]';

    -- Warm-start (2026-08-28): neu @RunIDGoiY duoc truyen (thuong la RunID cua lan chay truoc, truoc
    -- khi xoa de chay lai), lay toan bo KetQuaXep cua RunID do lam goi y ban dau cho CP-SAT — giup
    -- hoi tu nhanh hon nhieu khi chi sua vai dong data roi chay lai, thay vi giai lai tu con so 0.
    -- Loai tru dong MaMon='KHOAPHONG' (marker khoa phong, khong phai 1 tiet day that).
    DECLARE @GoiYBanDauJson NVARCHAR(MAX) = '[]';
    IF @RunIDGoiY IS NOT NULL
    BEGIN
        SELECT @GoiYBanDauJson = (
            SELECT MaLop, Thu, Buoi, Tiet, MaMon, MaGV
            FROM tblTKB_KetQuaXep
            WHERE RunID = @RunIDGoiY AND MaMon <> 'KHOAPHONG'
            FOR JSON PATH
        );
        IF @GoiYBanDauJson IS NULL SET @GoiYBanDauJson = '[]';
    END

    -- NeoO (2026-10-09, doi chieu TKB that tuan 8-11): nguoi xep tay GIU NGUYEN o cua 1 so mon qua tuan (SHTV: 18/35
    -- lop y het 5 tuan). Mon co MonQuyTac 'NeoTuanTruoc' {"phat":n} -> lay o cua tuan gan nhat TRUOC tuan dang xep trong
    -- tblTKB_NeoO, solver phat MEM moi lua chon nam ngoai o neo (khong cam cung).
    -- GIAI DOAN 1 (2026-10-10, thi nghiem tuan 10/11: neo moi mon -> thieu 8->2, giu o 20%->90%, 25'->5'): tuan nguon chon THEO KHOI —
    -- tuan gan nhat truoc tuan dang xep ma so o cua khoi do >= 85% so o lon nhat tung co VA khoi khong co ngay nghi tuan do
    -- (loai tuan co su kien: nghi, kiem tra, HDTN; neu khoi nao cung co su kien thi lay tuan moi nhat dat 85%).
    DECLARE @NeoOJson NVARCHAR(MAX) = '[]';
    IF @RunIDNeo IS NOT NULL
    BEGIN
        SELECT @NeoOJson = (
            SELECT k.MaLop, k.MaMon, k.Thu, k.Buoi, k.Tiet, @PhatNeoRun AS Phat
            FROM tblTKB_KetQuaXep k
            WHERE k.RunID = @RunIDNeo AND k.MaLop <> 'HOP' AND k.MaMon NOT IN ('HOP', 'SH', 'KHOAPHONG', 'HDTN1')
              AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = k.MaMon)
            FOR JSON PATH
        );
        IF @NeoOJson IS NULL SET @NeoOJson = '[]';
    END
    ELSE IF @TuanHienTai IS NOT NULL
    BEGIN
        ;WITH Dem AS (
            SELECT Tuan, LEFT(MaLop, 2) AS Khoi, COUNT(*) AS Cnt FROM tblTKB_NeoO WHERE Enable = 1 AND Tuan < @TuanHienTai GROUP BY Tuan, LEFT(MaLop, 2)
        ), Mx AS (
            SELECT Khoi, MAX(Cnt) AS MaxCnt FROM Dem GROUP BY Khoi
        ), Src AS (
            SELECT d.Khoi, COALESCE(MAX(CASE WHEN d.CoNghi = 0 THEN d.Tuan END), MAX(d.Tuan)) AS Tuan FROM (SELECT x.*, CASE WHEN EXISTS (SELECT 1 FROM tblTKB_NgayNghi_Tuan nn WHERE nn.Tuan = x.Tuan AND (nn.PhamVi = 'TRUONG' OR (nn.PhamVi = 'KHOI' AND nn.Khoi = x.Khoi) OR (nn.PhamVi = 'LOP' AND LEFT(nn.MaLop, 2) = x.Khoi))) THEN 1 ELSE 0 END AS CoNghi FROM Dem x) d INNER JOIN Mx m ON m.Khoi = d.Khoi WHERE d.Cnt >= 0.85 * m.MaxCnt GROUP BY d.Khoi
        )
        SELECT @NeoOJson = (
            SELECT n.MaLop, n.MaMon, n.Thu, n.Buoi, n.Tiet,
                   ISNULL(TRY_CAST(JSON_VALUE(q.ThamSo, '$.phat') AS INT), 60) AS Phat
            FROM tblTKB_NeoO n
            INNER JOIN Src s ON s.Khoi = LEFT(n.MaLop, 2) AND s.Tuan = n.Tuan
            JOIN tblTKB_MonQuyTac q ON q.MaMon = n.MaMon AND q.LoaiQuyTac = 'NeoTuanTruoc' AND q.Enable = 1
                                   AND (q.Khoi IS NULL OR q.Khoi = LEFT(n.MaLop, 2))
            WHERE n.Enable = 1
              AND (@Khoi = '' OR LEFT(n.MaLop, 2) IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
            FOR JSON PATH
        );
        IF @NeoOJson IS NULL SET @NeoOJson = '[]';
    END

    DECLARE @RunID INT;
    IF @RunIDDangXay IS NOT NULL AND EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunIDDangXay)
    BEGIN
        -- Tiep tuc tren chinh phien dang xay (da co du lieu khoa tay san trong tblTKB_KetQuaXep) —
        -- khong tao RunID moi, de ket qua Auto duoc gop chung voi phan da khoa.
        SET @RunID = @RunIDDangXay;
        UPDATE tblTKB_ChayAutoLog
        SET TrangThai = N'DangChay', MaxSecs = @MaxSecs, NguoiChay = @sys_UserID,
            SoNhuCau = (SELECT COUNT(*) FROM OPENJSON(@NhuCauJson)) + (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunIDDangXay),
            ThoiGianBatDau = SYSUTCDATETIME(), ThoiGianKetThuc = NULL,
            TuanHienTai = @TuanHienTai
        WHERE RunID = @RunID;
    END
    ELSE
    BEGIN
        -- Khoi cot log chi VARCHAR(2) — voi @Khoi gop nhieu khoi (vd '06,07') chi ghi log rut gon
        -- ('06+' bao gom ky tu '+' bao co gop them khoi khac), khong anh huong logic chay Auto that.
        -- TuanHienTai (2026-08-28): luu lai dung tuan da xep cho RunID nay — dinh muc theo R18 thay
        -- doi theo tuan (vd JA/BTHT/STEM), nen UI/checklist can biet chinh xac tuan nao de doi chieu
        -- dung, khong the doi chieu "moi tuan deu nhu nhau".
        INSERT INTO tblTKB_ChayAutoLog (Khoi, MaxSecs, TrangThai, NguoiChay, SoNhuCau, TuanHienTai)
        VALUES (
            CASE WHEN CHARINDEX(',', @Khoi) > 0 THEN LEFT(@Khoi, 1) + '+' ELSE @Khoi END,
            @MaxSecs, N'DangChay', @sys_UserID, (SELECT COUNT(*) FROM OPENJSON(@NhuCauJson)), @TuanHienTai
        );
        SET @RunID = SCOPE_IDENTITY();
    END

    -- Auto-khoa SH (Sinh hoat chu nhiem cap 2-3) vao dung Thu6-Chieu-Tiet4 cho GVCN cua tung lop,
    -- TRUOC KHI goi solver (kien truc moi 2026-08-30) — solver se khong bao gio thay hay dung toi
    -- don vi nay (da loai khoi @NhuCauJson o tren). Chi khoa cho lop nam trong @Khoi dang chay va
    -- CHUA co san dong SH nao trong RunID nay (tranh trung khi @RunIDDangXay da co san tu truoc).
    -- 2026-09-10: mac dinh Thu6/Chieu/Tiet4 CHUNG cho moi lop, tru khi co override rieng trong
    -- tblTKB_SH_OverrideSlot (vd 08C doi sang Sang-Tiet3 vi GVCN dang hoc cao hoc, han che day chieu).
    -- ⚠️ SUA 2026-09-12 (nguoi dung chi ra dung nguyen nhan cac vu be tac cô Nhi/GV371/GV791): truoc day
    -- dong SH nay auto-khoa Y HET 1 slot cho MOI lop MOI lan goi SP, du GVCN co dang ban cheo khoi/cheo
    -- cap hay khong — day KHONG PHAI thu "khong the thuong luong", no chi la 1 lua chon mac dinh tien
    -- loi, nhung khoa cung QUA SOM (truoc khi biet GVCN co xung dot gi khac) chinh la nguyen nhan truc
    -- tiep gay be tac (khong con duong lui, phai dao boi nhieu lop khac de chua chay). Tu nay: KHI CO
    -- @ChiGV (dang o Round 2, xu ly tung GV theo do khan hiem) — GVCN se "tu thuong luong" cho chinh
    -- minh: chi tu dong khoa slot mac dinh (hoac override) NEU GV ranh o do that (kiem tra qua
    -- tblTKB_KetQuaXep + GVBanCoDinh nhu 1 don vi NhuCau binh thuong, KHONG con auto-khoa mu quang) —
    -- neu GVCN dang ban dung slot mac dinh do (do day cheo khoi/cap), dong SH nay se ROI VAO NhuCau
    -- @ChiGV binh thuong de CP-SAT tu tim slot khac phu hop, khong con la "khong the doi" nua.
    IF @ChiGV IS NULL
    BEGIN
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
        SELECT DISTINCT @RunID, pc.MaLop, ISNULL(ov.Thu, 6), ISNULL(ov.Buoi, N'Chieu'), ISNULL(ov.Tiet, 4), 'SH', pc.MaGV, NULL, 0
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        LEFT JOIN tblTKB_SH_OverrideSlot ov ON ov.MaLop = pc.MaLop AND ov.Enable = 1
        WHERE pc.Enable = 1 AND pc.MaMon = 'SH'
          -- 2026-10-14: loc theo tuan (dong SH tat rieng tuan 13 cho 06A/08D van bi khoa vi thieu loc)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND NOT EXISTS (
              SELECT 1 FROM tblTKB_KetQuaXep k
              WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'SH'
          )
          -- FIX (2026-09-14, phat hien qua RunID 1269 — GV bi trung gio THAT vi nhanh @ChiGV IS NULL
          -- nay khong he kiem tra GV da ban chua, khac han nhanh @ChiGV IS NOT NULL ben duoi da co san
          -- guard nay): GV da ban dung slot mac dinh/override o 1 lop KHAC (day cheo khoi/cap) thi
          -- KHONG duoc ep khoa mu quang — de dong SH nay roi vao NhuCau cho CP-SAT tu tim slot khac.
          AND NOT EXISTS (
              SELECT 1 FROM tblTKB_KetQuaXep k3
              WHERE k3.RunID = @RunID AND k3.MaGV = pc.MaGV
                AND k3.Thu = ISNULL(ov.Thu, 6) AND k3.Buoi = ISNULL(ov.Buoi, N'Chieu') AND k3.Tiet = ISNULL(ov.Tiet, 4)
          );
    END
    ELSE
    BEGIN
        -- Dang xu ly rieng 1 GV (Round 2) va GV do co lam GVCN (co dong SH trong PCGD): thu khoa dung
        -- slot mac dinh/override NEU GV ranh that o do (khong dung slot nao khac trong tblTKB_KetQuaXep
        -- cua CHINH RunID nay) — neu KHONG ranh, de nguyen SH nam trong NhuCau de CP-SAT tu tim slot
        -- khac (khong ep buoc mu quang nua).
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
        SELECT DISTINCT @RunID, pc.MaLop, ISNULL(ov.Thu, 6), ISNULL(ov.Buoi, N'Chieu'), ISNULL(ov.Tiet, 4), 'SH', pc.MaGV, NULL, 0
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        LEFT JOIN tblTKB_SH_OverrideSlot ov ON ov.MaLop = pc.MaLop AND ov.Enable = 1
        WHERE pc.Enable = 1 AND pc.MaMon = 'SH' AND pc.MaGV = @ChiGV
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND NOT EXISTS (
              SELECT 1 FROM tblTKB_KetQuaXep k
              WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'SH'
          )
          AND NOT EXISTS (
              -- GV da ban dung slot mac dinh/override o 1 lop KHAC roi (vi du dang day mon khac
              -- khoi/cap khac gio do) -> khong ep, de CP-SAT tu tim cho.
              SELECT 1 FROM tblTKB_KetQuaXep k2
              WHERE k2.RunID = @RunID AND k2.MaGV = pc.MaGV
                AND k2.Thu = ISNULL(ov.Thu, 6) AND k2.Buoi = ISNULL(ov.Buoi, N'Chieu') AND k2.Tiet = ISNULL(ov.Tiet, 4)
          );
        -- Phan SH cua chinh GV nay KHONG khoa duoc o day (do da ban dung slot mac dinh/override) da
        -- duoc dong bo dua vao @NhuCauJson o tren (dieu kien EXISTS giong het NOT EXISTS o day) —
        -- CP-SAT se tu tim slot khac cho SH thay vi bi ep buoc mu quang.
    END;

    -- Auto-khoa HDTN1 (GVCN) dung vao slot "sinh hoat tap trung/chao co" da resolve cho @TuanHienTai
    -- (2026-09-12, theo phan bien nguoi dung — xem giai thich chi tiet o doan loai khoi NhuCau phia
    -- tren). Cung cong thuc voi SH: KHOA CUNG truoc khi goi solver, KHONG de CP-SAT tu quyet dinh vi
    -- tri. Uu tien tblTKB_ChaoCoKhoi_Tuan theo dung @TuanHienTai, fallback tblTKB_ChaoCoKhoi (quy luat
    -- co dinh moi tuan) neu khoi do khong co dong rieng cho tuan nay. Ap dung cho MOI lop dang co HDTN1
    -- (khong tach @ChiGV nhu SH — day la sinh hoat toan khoi theo hoi truong, khong phai truong hop
    -- GVCN "tu thuong luong" giua nhieu vai tro nhu SH).
    -- SUA 2026-09-21: chi lich rieng theo tuan, KHONG fallback bang co dinh.
    ;WITH ChaoCoResolved AS (
        SELECT cct.Khoi, cct.Thu, cct.Buoi, cct.Tiet
        FROM tblTKB_ChaoCoKhoi_Tuan cct
        WHERE cct.Enable = 1 AND cct.Tuan = @TuanHienTai
    )
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT DISTINCT @RunID, pc.MaLop, cr.Thu, cr.Buoi, cr.Tiet, 'HDTN1', pc.MaGV, NULL, 0
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    INNER JOIN ChaoCoResolved cr ON cr.Khoi = l.Khoi
    WHERE pc.Enable = 1 AND pc.MaMon = 'HDTN1'
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
      -- SUA 2026-09-12: doi tu "NOT EXISTS (...MaMon='HDTN1')" (chan CA dong bat ke slot nao) sang
      -- kiem tra DUNG slot cr.Thu/cr.Buoi/cr.Tiet — vi tu nay 1 lop co THE co 2 dong HDTN1 (chao co +
      -- Thu6, xem doan INSERT ben duoi), kiem tra "bat ky dong HDTN1 nao" se chan nham lan insert Thu6
      -- (hoac nguoc lai) khi 1 trong 2 da ton tai truoc.
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'HDTN1'
            AND k.Thu = cr.Thu AND k.Buoi = cr.Buoi AND k.Tiet = cr.Tiet
      )
      -- FIX (2026-09-14, phat hien qua RunID 1269 — GV bi trung gio THAT, vd GVCN vua day HDTN1 khoi
      -- minh vua day mon khac o khoi/cap khac dung slot Chao co "linh hoat"): doan nay TRUOC GIO khong
      -- kiem tra GV da ban chua truoc khi ep khoa cung — sua giong het pattern SH ben tren, GV da ban
      -- dung slot nay o dau khac thi KHONG duoc ep, de rieng dong HDTN1 nay lai (van nam trong PCGD,
      -- se tu roi vao NhuCau binh thuong cho CP-SAT tim slot khac neu con cho).
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k4
          WHERE k4.RunID = @RunID AND k4.MaGV = pc.MaGV AND k4.Thu = cr.Thu AND k4.Buoi = cr.Buoi AND k4.Tiet = cr.Tiet
      );

    -- Auto-khoa HDTN1 tiet CUOI NGAY Thu 6 (2026-09-12, theo de xuat nguoi dung "gan mac dinh, chi
    -- GV doi lich dac thu moi sua tay") — CUNG kien truc mac dinh+override voi SH/chao co: mac dinh
    -- Thu=6/Chieu/Tiet=4 CHUNG cho moi lop (xac nhan Tieu hoc luon co dung 4 tiet/buoi chieu, khong
    -- ngoai le — xem TkbCpSatSolver.SoTietThatCuaBuoi), tru khi co override rieng trong
    -- tblTKB_HDTN1_OverrideSlot (GV doi lich dac thu). Chi ap dung khi SoTietChuanTuan > 1 (Tieu hoc,
    -- khac cap 2-3 chi co dung 1 tiet/tuan da dung het cho chao co, khong con Thu6 rieng).
    INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
    SELECT DISTINCT @RunID, pc.MaLop, ISNULL(ov.Thu, 6), ISNULL(ov.Buoi, N'Chieu'), ISNULL(ov.Tiet, 4), 'HDTN1', pc.MaGV, NULL, 0
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_HDTN1_OverrideSlot ov ON ov.MaLop = pc.MaLop AND ov.Enable = 1
        -- 2026-10-07: override theo tuan (Tuan = tuan dang xep) uu tien hon override chung (Tuan NULL)
        AND (ov.Tuan = @TuanHienTai OR (ov.Tuan IS NULL AND NOT EXISTS (SELECT 1 FROM tblTKB_HDTN1_OverrideSlot o2
             WHERE o2.MaLop = pc.MaLop AND o2.Enable = 1 AND o2.Tuan = @TuanHienTai)))
    WHERE pc.Enable = 1 AND pc.MaMon = 'HDTN1' AND pc.SoTietChuanTuan > 1
      AND (@HocKy = '' OR pc.HocKy = @HocKy)
      AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
      AND NOT EXISTS (
          SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = 'HDTN1'
            AND k.Thu = ISNULL(ov.Thu, 6) AND k.Buoi = ISNULL(ov.Buoi, N'Chieu') AND k.Tiet = ISNULL(ov.Tiet, 4)
      );

    UPDATE tblTKB_ChayAutoLog
    SET SoNhuCau = (SELECT COUNT(*) FROM OPENJSON(@NhuCauJson))
        + (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon = 'SH')
        + (SELECT COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaMon = 'HDTN1')
    WHERE RunID = @RunID;

    -- FIX (2026-08-30, phat hien qua loi trung slot that o lop 07A khi dung ky thuat "warm-start" —
    -- khoa cung lich that cua 1 GV vao tblTKB_KetQuaXep TRUOC khi goi Auto qua @RunIDDangXay/ChenKhoa):
    -- solver truoc day CHI biet "GV nay dang ban" (qua viec loai khoi NhuCau) chu KHONG biet "LOP nay
    -- da co tiet o khung gio do" — nen mon khac (do GV khac day) van bi xep DE len dung slot da khoa,
    -- day noi dung dung ra thanh trong o cho khac. Sua: gui them "LopDaKhoa" — danh sach TOAN BO
    -- (MaLop,Thu,Buoi,Tiet) da co san trong tblTKB_KetQuaXep cho @RunID nay (bao gom SH auto-khoa o
    -- tren VA moi du lieu khoa tay ben ngoai qua ChenKhoa/@RunIDDangXay) — solver phai cam TUYET DOI
    -- moi don vi khac cua CHINH LOP do dung vao cac khung gio nay.
    -- LaMarker (2026-10-10): o chi co marker "Tach nhom" (MaMon = MaCumTach) — solver R23 khong coi la lop nguon ban mon khac.
    DECLARE @LopDaKhoaJson NVARCHAR(MAX) = (
        SELECT k.MaLop, k.Thu, k.Buoi, k.Tiet,
               CAST(MIN(CASE WHEN c.MaCumTach IS NULL THEN 0 ELSE 1 END) AS BIT) AS LaMarker,
               -- 2026-10-14: mon cua o khoa (quy tac KhongNgayLien can biet tiet da xep o buoc truoc)
               MIN(CASE WHEN c.MaCumTach IS NULL THEN k.MaMon END) AS MaMon
        FROM tblTKB_KetQuaXep k
        LEFT JOIN tblTKB_CumTach c ON c.MaCumTach = k.MaMon
        WHERE k.RunID = @RunID
        GROUP BY k.MaLop, k.Thu, k.Buoi, k.Tiet
        FOR JSON PATH
    );
    IF @LopDaKhoaJson IS NULL SET @LopDaKhoaJson = '[]';

    -- Cum tach nhom hoc sinh (2026-08-30, THPT R23): nhom con (lop ao AVn/Xn) phai xep TRUNG DUNG
    -- slot voi nhau, dong thoi lop nguon (lop that cap hoc sinh) phai TRONG dung slot do — xem
    -- tblTKB_CumTach/_LopNguon/_NhomCon va rule R23 trong TkbCpSatSolver.cs.
    -- FOR JSON PATH tren 1 cot don se ra mang OBJECT [{"MaLop":"x"}] chu khong phai mang string
    -- phang ["x"] ma C# List<string> can — phai tu ghep chuoi qua STRING_AGG + STRING_ESCAPE.
    DECLARE @CumTachJson NVARCHAR(MAX) = (
        SELECT ct.MaCumTach,
               JSON_QUERY('[' + ISNULL((SELECT STRING_AGG('"' + STRING_ESCAPE(MaLop, 'json') + '"', ',') FROM tblTKB_CumTach_LopNguon WHERE CumTachID = ct.ID), '') + ']') AS LopNguon,
               JSON_QUERY('[' + ISNULL((SELECT STRING_AGG('"' + STRING_ESCAPE(MaLop, 'json') + '"', ',') FROM tblTKB_CumTach_NhomCon WHERE CumTachID = ct.ID), '') + ']') AS NhomCon
        FROM tblTKB_CumTach ct
        WHERE ct.Enable = 1
          AND (@Khoi = '' OR ct.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
        FOR JSON PATH
    );
    IF @CumTachJson IS NULL SET @CumTachJson = '[]';

    -- Diem phat cum tach theo do khan hiem GV (2026-09-26, Round 2 nhan biet GV khan hiem — tong quat, KHONG rieng GV nao): cum tach duoc xep
    -- 'mu' voi cac mon con lai cua Lop Nguon, nen co the chiem dung o hiem hoi ma GV it o cho phep (co lich ban tuan nay) day lop do
    -- (RunID 1384: cum AV khoi 11 chiem Thu 2 / Thu 6 sang -> co Yen Nhi khong xep du 11C/11D). Phat(cum, slot) = SUM ty le^2 * 1000 cua cac GV
    -- (co lich ban tuan nay) dang day cac lop nguon cua cum va DUOC phep day tai slot do; ty le = tong tiet can / so o cho phep (50 tru o ban).
    DECLARE @CumTachSlotPhatJson NVARCHAR(MAX);
    ;WITH CamG AS (
        SELECT g.MaGV, g.Thu, x.Buoi, y.Tiet
        FROM tblTKB_GVCamTuyetDoi_Tuan g
        CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) v(Buoi) WHERE ISNULL(g.Buoi, '') = '' OR g.Buoi = v.Buoi) x
        CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) w(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = w.Tiet) y
        WHERE g.Tuan = @TuanHienTai
        GROUP BY g.MaGV, g.Thu, x.Buoi, y.Tiet
    ),
    SoCam AS (SELECT MaGV, COUNT(*) AS N FROM CamG GROUP BY MaGV),
    GVCum AS (
        SELECT DISTINCT ct.MaCumTach, pc.MaGV
        FROM tblTKB_CumTach ct
        INNER JOIN tblTKB_CumTach_LopNguon ln ON ln.CumTachID = ct.ID
        INNER JOIN tblTKB_PhanCongGiangDay pc ON pc.MaLop = ln.MaLop AND pc.Enable = 1 AND pc.MaGV IS NOT NULL
        INNER JOIN tblTKB_GiaoVien gv ON gv.MaGV = pc.MaGV
        WHERE ct.Enable = 1 AND (@Khoi = '' OR ct.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    ),
    Can AS (
        SELECT pc.MaGV, SUM(pc.SoTietChuanTuan) AS TongCan
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND pc.MaMon NOT IN ('SH', 'HDTN1')
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaGV
    ),
    W AS (
        SELECT gc.MaCumTach, gc.MaGV, sc.N AS SoCam,
               CAST(1000.0 * POWER(CAST(cn.TongCan AS FLOAT) / NULLIF(50 - sc.N, 0), 2) AS INT) AS Trong
        FROM GVCum gc
        INNER JOIN SoCam sc ON sc.MaGV = gc.MaGV AND sc.N < 50
        INNER JOIN Can cn ON cn.MaGV = gc.MaGV
    ),
    Slots AS (
        SELECT th.Thu, bu.Buoi, ti.Tiet FROM (VALUES(2),(3),(4),(5),(6)) th(Thu)
        CROSS JOIN (VALUES('Sang'),('Chieu')) bu(Buoi) CROSS JOIN (VALUES(1),(2),(3),(4),(5)) ti(Tiet)
    ),
    Phat AS (
        SELECT w.MaCumTach, s.Thu, s.Buoi, s.Tiet, SUM(w.Trong) AS Phat
        FROM W w CROSS JOIN Slots s
        WHERE NOT EXISTS (SELECT 1 FROM CamG c WHERE c.MaGV = w.MaGV AND c.Thu = s.Thu AND c.Buoi = s.Buoi AND c.Tiet = s.Tiet)
        GROUP BY w.MaCumTach, s.Thu, s.Buoi, s.Tiet
    )
    SELECT @CumTachSlotPhatJson = (SELECT MaCumTach, Thu, Buoi, Tiet, Phat FROM Phat WHERE Phat > 0 FOR JSON PATH);
    IF @CumTachSlotPhatJson IS NULL SET @CumTachSlotPhatJson = '[]';

    -- Cap mon dong bo gio (2026-09-10, R24): 2 (Lop,Mon) phai xep TRUNG DUNG slot voi nhau, khong
    -- quan tam co chung 1 Cum tach hay khong (dung ca cho cap XUYEN CUM, vd chuyen de Tin cua 10A2
    -- va 10F1) — xem tblTKB_CapMonDongBoGio va rule R24 trong TkbCpSatSolver.cs.
    DECLARE @CapMonDongBoJson NVARCHAR(MAX) = (
        SELECT MaLopA, MaMonA, MaLopB, MaMonB
        FROM tblTKB_CapMonDongBoGio c
        WHERE c.Enable = 1
          AND (@Khoi = '' OR c.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          -- 2026-10-07: dong co Tuan = tuan dang xep GHI DE dong chung (Tuan NULL) cung cap lop (MaLopA, MaLopB);
          -- dong ghi de Enable = 0 nghia la "tuan nay khong dong bo cap lop nay" (vd 01D/01DTG tuan 11).
          AND (c.Tuan = @TuanHienTai OR (c.Tuan IS NULL AND NOT EXISTS (SELECT 1 FROM tblTKB_CapMonDongBoGio o
               WHERE o.MaLopA = c.MaLopA AND o.MaLopB = c.MaLopB AND o.Tuan = @TuanHienTai)))
        FOR JSON PATH
    );
    IF @CapMonDongBoJson IS NULL SET @CapMonDongBoJson = '[]';

    -- GV cam tuyet doi (2026-09-02, fix bug "GV bao ban van bi xep lai dung ngay do"; mo rong
    -- 2026-09-04 sang tblTKB_GVCamTuyetDoi_Tuan — fix bug thuc te "bao ban tuan CHUA xep Auto lan
    -- nao thi bi mat trang" vi ban ghi cu bat buoc phai gan voi 1 RunID DA TON TAI). Nguon 1 (cu):
    -- ban ghi gan voi CHINH @RunID nay. Nguon 2 (moi): ban ghi gan theo TUAN (khong can RunID nao
    -- ton tai truoc), Buoi='' hoac Tiet=NULL nghia la "ca buoi/ca ngay" — GIAN AN TOAN thanh sieu
    -- tap Tiet 1-5 (solver tu bo qua Tiet khong ton tai that vi choice-loop cua tung Lop da tu gioi
    -- han theo SoTietThatCuaBuoi, entry thua khong khop choice nao thi vo hai).
    -- FIX (2026-09-14, phat hien qua du lieu that RunID 1269 — nguoi dung phat hien "GV day STEM/AI/
    -- Boi o tieu hoc cung la GV day cap 2-3"): 15 truong hop GV bi xep TRUNG GIO THAT (vd NV0000038
    -- Thu2-Sang4 vua day 02B-GDTC vua day 10B-GDTC). Nguyen nhan: _lopDaKhoa (C#) CHI bao ve LOP (mon
    -- khac khong duoc chen vao slot cua lop DA khoa), KHONG bao ve GV — khi 1 GV da duoc khoa xong o
    -- 1 Round rieng (vd Round 1.5 khoi 10-12), GV do bi loai khoi NhuCau cua Round sau (Round 2/4 khoi
    -- 1-9 rieng) vi da xep du dinh muc, solver o Round sau HOAN TOAN KHONG BIET GV do da ban san o cac
    -- slot nao (chi biet lop nao da ban, khong biet GV nao gan voi lop do). Sua: them nguon thu 3 vao
    -- GVCamTuyetDoi (co san co che HARD cam GV dung tai 1 slot, khong can sua C#) — MOI slot ma GV do
    -- DA CO tiet that trong chinh @RunID nay (bat ke Khoi/Round nao xep, tru marker Cum tach khong
    -- phai GV that) deu bi cam tuyet doi dung lai cho don vi MOI trong lan goi nay.
    DECLARE @GVCamTuyetDoiJson NVARCHAR(MAX) = (
        SELECT MaGV, Thu, Buoi, Tiet FROM (
            SELECT MaGV, Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID
            UNION
            SELECT g.MaGV, g.Thu, bb.Buoi, tt.Tiet
            FROM tblTKB_GVCamTuyetDoi_Tuan g
            CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
            CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
            WHERE g.Tuan = @TuanHienTai
            UNION
            SELECT k.MaGV, k.Thu, k.Buoi, k.Tiet
            FROM tblTKB_KetQuaXep k
            INNER JOIN tblTKB_GiaoVien gv ON gv.MaGV = k.MaGV
            WHERE k.RunID = @RunID AND k.Tiet <= 5
        ) merged
        FOR JSON PATH
    );
    IF @GVCamTuyetDoiJson IS NULL SET @GVCamTuyetDoiJson = '[]';

    -- Vung du phong GV (2026-09-30, theo de xuat nguoi dung "GV thinh giang sang T2,4 nhung con 1 buoi backup Chieu T3"):
    -- CHI lay tu du lieu THAT khai bao trong tblTKB_GVBackupSlot_Tuan (khong tu suy dien) — xem ghi chu day du trong
    -- TkbCpSatSolver.cs (_gvBackupSlot). Trung voi 1 o dang cam tuyet doi (MucDo=0 kieu cu) thi o do VAN cam tuyet doi
    -- (cam tuyet doi luon thang the, backup chi co tac dung tren cac o solver dang coi la "trong" theo NhuCau).
    -- 2026-10-07 (RunID 1499: 04D/04G thieu vi Tin Xuan Hung / MT Cao Khai day ca khoi 6 bi buoc 6-9 xep vao dung gio
    -- hop khoi 4): khi giai CAP TREN (khong co khoi tieu hoc trong @Khoi), GV CHUYEN co day tieu hoc bi phat 400/o neu
    -- xep vao gio hop khoi (cung) cua khoi tieu hoc ho day — giu cho cho lop tieu hoc can GV chuyen luc GVCN hop.
    DECLARE @KhongCoTH BIT = CASE WHEN @Khoi <> '' AND NOT EXISTS (SELECT 1 FROM STRING_SPLIT(@Khoi, ',') WHERE value < '06') THEN 1 ELSE 0 END;
    DECLARE @GVBackupSlotJson NVARCHAR(MAX) = (
        SELECT MaGV, Thu, Buoi, Tiet, SUM(Phat) AS Phat FROM (
            SELECT MaGV, Thu, Buoi, Tiet, Phat
            FROM tblTKB_GVBackupSlot_Tuan
            WHERE Tuan = @TuanHienTai
            UNION ALL
            -- 2026-10-10 (RunID 1546 thieu 05C/05E: Tin/AI Tran Dinh Ngoc bi buoc 6-9 xep AI 06C vao gio hop khoi 5 T5 chieu
            -- t1-2): truoc chi doc hop "Cung=1" (lich co dinh) -> bo sot hop nhap theo tuan (LoaiNhom 'Tuan', Cung=0). Nay doc moi
            -- lich hop GVCN tieu hoc (giong OChuyenBatBuoc) va tinh theo TUNG LOP: GV chuyen bi giu cho o gio hop cua GVCN lop ho day.
            SELECT DISTINCT c.MaGV, k.Thu, k.Buoi, k.Tiet, 400
            FROM (
                SELECT DISTINCT pc.MaGV, LEFT(pc.MaLop, 3) AS LopGoc
                FROM tblTKB_PhanCongGiangDay pc INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
                WHERE @KhongCoTH = 1 AND pc.Enable = 1 AND pc.HocKy = @HocKy AND l.Khoi IN ('01','02','03','04','05')
                  AND pc.MaGV LIKE 'NV%' AND pc.SoTietChuanTuan > 0
                  AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
                  AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
                  AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
                  AND NOT EXISTS (SELECT 1 FROM tblTKB_Lop g WHERE g.GVCN = pc.MaGV AND g.Khoi IN ('01','02','03','04','05'))
            ) c
            INNER JOIN (
                SELECT DISTINCT l.MaLop, h.Thu, h.Buoi, h.Tiet
                FROM tblTKB_Lop l INNER JOIN dbo.fnTkbLichHopGV(@TuanHienTai) h ON h.MaGV = l.GVCN
                WHERE l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND LEN(l.MaLop) = 3 AND h.Tiet <= 4
                  AND h.LoaiNhom <> 'KhoiCap23SH'
            ) k ON k.MaLop = c.LopGoc
        ) x
        GROUP BY MaGV, Thu, Buoi, Tiet
        FOR JSON PATH
    );
    IF @GVBackupSlotJson IS NULL SET @GVBackupSlotJson = '[]';

    -- PhongGiuCho (2026-10-10, RunID 1589): khi giai CAP TREN (khong co tieu hoc), phat 300/o lop cap tren dung PHONG CHUYEN (phong co
    -- dinh cua lop tieu hoc, vd AN2 cua 05F) dung gio GVCN lop tieu hoc do hop — giu phong cho GV bo mon day lop tieu hoc luc GVCN hop.
    DECLARE @PhongGiuChoJson NVARCHAR(MAX) = (
        SELECT MaPhong, Thu, Buoi, Tiet, 300 AS Phat FROM (
            SELECT DISTINCT pl.PhongCsv AS MaPhong, h.Thu, h.Buoi, h.Tiet
            FROM tblTKB_Lop l
            INNER JOIN dbo.fnTkbLichHopGV(@TuanHienTai) h ON h.MaGV = l.GVCN AND h.LoaiNhom <> 'KhoiCap23SH' AND h.Tiet <= 4
            INNER JOIN #PoolLop pl ON pl.MaLop = l.MaLop AND pl.SoPhong = 1
            WHERE @KhongCoTH = 1 AND l.Enable = 1 AND l.Khoi < '06' AND LEN(l.MaLop) = 3
        ) x
        FOR JSON PATH
    );
    IF @PhongGiuChoJson IS NULL SET @PhongGiuChoJson = '[]';

    -- Ngay nghi (2026-09-03, xem tblTKB_NgayNghi/spAPI_TkbNgayNghi_ApDung; mo rong 2026-09-04 sang
    -- tblTKB_NgayNghi_Tuan cung ly do nhu GVCamTuyetDoi_Tuan o tren) — nghi le/nghi hoc cho 1 Lop cu
    -- the tai dung slot, pham vi nguoi dung chon la Lop/Khoi/Truong nhung tai day resolve san ve
    -- danh sach MaLop cu the (solver chi biet cam theo Lop, khong tu hieu Khoi/Truong).
    DECLARE @NgayNghiJson NVARCHAR(MAX) = (
        SELECT MaLop, Thu, Buoi, Tiet FROM (
            SELECT l.MaLop, nn.Thu, nn.Buoi, nn.Tiet
            FROM tblTKB_NgayNghi nn
            CROSS APPLY (
                SELECT MaLop FROM tblTKB_Lop WHERE Enable = 1 AND (
                    (nn.PhamVi = 'LOP' AND MaLop = nn.MaLop)
                    OR (nn.PhamVi = 'KHOI' AND Khoi = nn.Khoi)
                    OR (nn.PhamVi = 'TRUONG')
                )
            ) l
            WHERE nn.RunID = @RunID
            UNION
            SELECT l2.MaLop, nt.Thu, bb.Buoi, tt.Tiet
            FROM tblTKB_NgayNghi_Tuan nt
            CROSS APPLY (
                SELECT MaLop FROM tblTKB_Lop WHERE Enable = 1 AND (
                    (nt.PhamVi = 'LOP' AND MaLop = nt.MaLop)
                    OR (nt.PhamVi = 'KHOI' AND Khoi = nt.Khoi)
                    OR (nt.PhamVi = 'TRUONG')
                )
            ) l2
            CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE nt.Buoi = '' OR nt.Buoi = x.Buoi) bb
            CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE nt.Tiet IS NULL OR nt.Tiet = y.Tiet) tt
            WHERE nt.Tuan = @TuanHienTai
        ) merged
        FOR JSON PATH
    );
    IF @NgayNghiJson IS NULL SET @NgayNghiJson = '[]';

    DECLARE @Body NVARCHAR(MAX) = N'{'
        + N'"NhuCau":' + @NhuCauJson
        + N',"MonBatBuocXepDoi":' + @MonBatBuocXepDoiJson
        + N',"GVBanCoDinh":' + @GVBanCoDinhJson
        + N',"PhongPoolTheoMon":' + @PhongPoolTheoMonJson
        + N',"KhoaPhongDungChung":' + @KhoaPhongDungChungJson
        + N',"ChaoCoKhoi":' + @ChaoCoKhoiJson
        + N',"MonQuyTac":' + @MonQuyTacJson
        + N',"GoiYBanDau":' + @GoiYBanDauJson
        + N',"LopDaKhoa":' + @LopDaKhoaJson
        -- 2026-10-16: phat tiet trong khong o cuoi buoi (lop khoi 06-12) — 40 (80 thi tieu hoc thieu 15 tiet, RunID 1645)
        + N',"PhatLoLop":0'
        + N',"CumTach":' + @CumTachJson
        + N',"CumTachSlotPhat":' + @CumTachSlotPhatJson
        + N',"CapMonDongBo":' + @CapMonDongBoJson
        + N',"GVCamTuyetDoi":' + @GVCamTuyetDoiJson
        + N',"GVBackupSlot":' + @GVBackupSlotJson
        + N',"OChuyenBatBuoc":' + @OChuyenJson
        + N',"NgayNghi":' + @NgayNghiJson
        + N',"NeoO":' + @NeoOJson
        + N',"PhongGiuCho":' + @PhongGiuChoJson
        + N',"MaxTietMoiNgay":8'
        + N',"R4BatBuoc":' + CASE WHEN @R4BatBuoc = 1 THEN 'true' ELSE 'false' END
        + N',"R9BatBuoc":' + CASE WHEN @R9BatBuoc = 1 THEN 'true' ELSE 'false' END
        + N',"R7BatBuoc":' + CASE WHEN @R7BatBuoc = 1 THEN 'true' ELSE 'false' END
        + N',"R22BatBuoc":' + CASE WHEN @R22BatBuoc = 1 THEN 'true' ELSE 'false' END
        + N',"HopBatBuoc":' + CASE WHEN @HopBatBuoc = 1 THEN 'true' ELSE 'false' END
        + N',"MaxSecs":' + CAST(@MaxSecs AS VARCHAR(10))
        + N',"KhongChoSkip":' + CASE WHEN @KhongChoSkip = 1 THEN 'true' ELSE 'false' END
        + N'}';

    IF @ChiTraVeBody = 1
    BEGIN
        SELECT @Body AS Body, @RunID AS RunID;
        RETURN;
    END

    DECLARE @StartResponse NVARCHAR(MAX);
    -- 2026-09-17 (theo de xuat nguoi dung "chuyen han sang server test de test lai" — server moi
    -- 192.168.100.249 manh hon han: 24 core Xeon Silver 4510 vs 4 core AMD EPYC 7H12 cua server cu,
    -- 117GB RAM (114GB rang) vs 15GB (chi con 3.8GB rang) — server cu dang gan can bo nho): doi dia
    -- chi solver tu 222.255.238.146 (production cu) sang 192.168.100.249 (server test noi bo, chi
    -- truy cap duoc qua VPN LHBS). Neu can rollback ve server cu, doi lai dung 1 dong nay.
    -- 2026-10-10: goi thang Kestrel :8080 (nginx :7778 gioi han body 1MB -> 413 khi body ca truong ~1,07MB, nghi la goc LoiGoiSolver o buoc va)
    SELECT @StartResponse = dbo.httpCall('POST', 'http://192.168.100.249:8080/api/solve/start', 'Content-Type: application/json', @Body);

    DECLARE @JobID VARCHAR(50) = JSON_VALUE(@StartResponse, '$.jobId');

    IF @JobID IS NULL
    BEGIN
        UPDATE tblTKB_ChayAutoLog
        SET ThoiGianKetThuc = SYSUTCDATETIME(), TrangThai = N'LoiGoiSolver', LoiChiTiet = @StartResponse
        WHERE RunID = @RunID;

        IF @ChiCapNhat = 0
        BEGIN
        SELECT @RunID AS RunID, N'LoiGoiSolver' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               ISNULL(@StartResponse, N'Không khởi động được job solver') AS ThongBao;
        END
        RETURN;
    END

    -- Lưu tạm JobID vào LoiChiTiet trong lúc DangChay (không đổi schema); spAPI_TkbChayAutoTrangThai đọc lại để poll.
    UPDATE tblTKB_ChayAutoLog SET LoiChiTiet = @JobID WHERE RunID = @RunID;

    IF @ChiCapNhat = 0
        SELECT @RunID AS RunID, N'DangChay' AS TrangThai, CAST(0 AS BIT) AS KhaThi, CAST(NULL AS NVARCHAR(500)) AS ThongBao;
END