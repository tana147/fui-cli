CREATE PROCEDURE spAPI_TkbGiaiTietDoiTuanTu
    @Khoi VARCHAR(50),
    @HocKy VARCHAR(4) = 'HK1',
    @TuanHienTai INT = NULL,
    @MaxSecsPerGV INT = 90,
    @SoGVMoiLan INT = 3,
    @ChiCumTach TINYINT = 2,
    @TrangThaiRa VARCHAR(12) = NULL OUTPUT,
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- MO TA NGAN (2026-09-18, chuan hoa theo thiet ke da thong nhat sau khi doi chung du lieu that
    -- tuan 8 — xem tblTKB_GVGiaoVien HoTen 'Nguyen Viet Hieu'/'Do Thi Duyen'): dung chung cho Round 3/
    -- 5/6 — giai TIET DOI theo TUNG GV MOT (giong kien truc Round 7/DoKhanHiem), thay vi giai GOP toan
    -- bo GV/mon tiet doi trong 1 lan CP-SAT duy nhat (cach cu). Ly do: doi chung lich THAT phat hien 2
    -- nguyen nhan that bai khac nhau can 2 bien phap trong CUNG 1 kien truc nay:
    --   (a) GV hep gio that (vd Nguyen Viet Hieu, GDQP): giai gop de bi GV khac "chiem" slot truoc khi
    --       den luot GV hep — can THU TU uu tien dung (GV cang it "cap tiet lien ke kha dung" cang xu ly
    --       som).
    --   (b) GV KHONG hep gio nhung day NHIEU lop tiet doi (vd Do Thi Duyen day 5 lop ENG2 khoi 6, Luu
    --       Gia Tue 4 lop khoi 8 — ca 2 deu KHONG co BuoiBanCoDinh/GVCamTuyetDoi_Tuan rieng, lich that
    --       phai dung CA TUAN moi du cho): giai gop nhieu GV/mon cung luc trong 1 lan CP-SAT khien bai
    --       toan con cua GV nay "chim" giua dam dong, khong du ngan sach thoi gian rieng du sau — can
    --       NGAN SACH GIAI RIENG (mot lan goi spAPI_TkbChayAuto @ChiGV rieng), khong phai thu tu.
    -- Ca 2 nguyen nhan deu duoc giai quyet bang CUNG 1 thay doi: tach thanh vong lap giai TUNG GV mot,
    -- co ngan sach @MaxSecsPerGV rieng, khoa NGAY sau moi GV — dung nguyen kien truc da chung minh dung
    -- cua Round 7, ap dung SOM HON (truoc khi mon thuong vao cuoc), thay vi 1 EXEC gop @ChiMonDoi=1 cho
    -- ca @Khoi nhu cach cu.
    IF @MaxSecsPerGV IS NULL OR @MaxSecsPerGV < 10 SET @MaxSecsPerGV = 10;
    IF @MaxSecsPerGV > 180 SET @MaxSecsPerGV = 180;
    IF @SoGVMoiLan IS NULL OR @SoGVMoiLan < 1 SET @SoGVMoiLan = 1;

    IF @RunID IS NULL OR NOT EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID)
    BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThaiCuoiCung, 0 AS SoGVConLai;
        RETURN;
    END

    -- Tinh @tmpGVHop (GV -> tap slot hop to co dinh) — dung CHINH cong thuc da chuan hoa o Round 7/
    -- spAPI_TkbChayAuto (GVDiem), copy nguyen de tinh dung SoCapKhaDung (khong bi tinh du HOP la "ranh").
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

    -- Tap GV can xet: co PCGD thuoc mon tiet doi (BatBuocXepDoi=1 hoac MonQuyTac dang Pattern, giong
    -- dung dieu kien @ChiMonDoi trong spAPI_TkbChayAuto) trong pham vi @Khoi, CHUA du (SoTietDaXep <
    -- SoTietChuanTuan).
    DECLARE @DsGV TABLE (MaGV VARCHAR(9) PRIMARY KEY, SoCapCanXep FLOAT, SoCapKhaDung INT, TyLeCang FLOAT, DaXuLy BIT NOT NULL DEFAULT 0);

    ;WITH PCGDTietDoi AS (
        SELECT pc.MaGV, pc.MaLop, pc.MaMon, pc.SoTietChuanTuan,
            (SELECT COUNT(*) FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon AND k.MaGV = pc.MaGV) AS SoTietDaXep
        FROM tblTKB_PhanCongGiangDay pc
        INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
        WHERE pc.Enable = 1
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')))
          AND (@HocKy = '' OR pc.HocKy = @HocKy)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
          AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
          AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
          AND (
              EXISTS (SELECT 1 FROM tblTKB_MonHoc mh WHERE mh.MaMon = pc.MaMon AND mh.BatBuocXepDoi = 1)
              OR EXISTS (
                  SELECT 1 FROM tblTKB_MonQuyTac mq WHERE mq.MaMon = pc.MaMon AND mq.Enable = 1
                    AND mq.LoaiQuyTac LIKE '%_Pattern' AND mq.LoaiQuyTac <> 'HDTN1_Pattern'
              )
          )
          AND (
              @ChiCumTach = 0
              OR (@ChiCumTach = 2 AND NOT EXISTS (
                  SELECT 1 FROM tblTKB_CumTach_NhomCon ctn6
                  INNER JOIN tblTKB_CumTach ct6 ON ct6.ID = ctn6.CumTachID AND ct6.Enable = 1
                  WHERE ctn6.MaLop = pc.MaLop
              ))
          )
    ),
    GVCanXep AS (
        SELECT MaGV, SUM(CAST(SoTietChuanTuan - SoTietDaXep AS FLOAT)) / 2.0 AS SoCapCanXep
        FROM PCGDTietDoi
        WHERE SoTietDaXep < SoTietChuanTuan
        GROUP BY MaGV
        HAVING SUM(SoTietChuanTuan - SoTietDaXep) > 0
    ),
    -- Bit-mask (tiet1=bit0..tiet5=bit4, 1=RANH) tung (GV,Thu,Buoi) — tru GVCamTuyetDoi/_Tuan/HOP/da xep.
    BanSlot AS (
        SELECT MaGV, Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID
        UNION
        SELECT g.MaGV, g.Thu, bb.Buoi, tt.Tiet
        FROM tblTKB_GVCamTuyetDoi_Tuan g
        CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE g.Buoi = '' OR g.Buoi = x.Buoi) bb
        CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4),(5)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
        WHERE g.Tuan = @TuanHienTai
        UNION
        SELECT MaGV, Thu, Buoi, Tiet FROM @tmpGVHop
        UNION
        SELECT MaGV, Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID
    ),
    ThuBuoi AS (
        SELECT Thu, Buoi FROM (VALUES(2,'Sang'),(2,'Chieu'),(3,'Sang'),(3,'Chieu'),(4,'Sang'),(4,'Chieu'),
                                      (5,'Sang'),(5,'Chieu'),(6,'Sang'),(6,'Chieu')) x(Thu,Buoi)
    ),
    Mask AS (
        SELECT gc.MaGV, tb.Thu, tb.Buoi,
            (CASE WHEN NOT EXISTS (SELECT 1 FROM BanSlot b WHERE b.MaGV=gc.MaGV AND b.Thu=tb.Thu AND b.Buoi=tb.Buoi AND b.Tiet=1) THEN 1 ELSE 0 END) +
            (CASE WHEN NOT EXISTS (SELECT 1 FROM BanSlot b WHERE b.MaGV=gc.MaGV AND b.Thu=tb.Thu AND b.Buoi=tb.Buoi AND b.Tiet=2) THEN 2 ELSE 0 END) +
            (CASE WHEN NOT EXISTS (SELECT 1 FROM BanSlot b WHERE b.MaGV=gc.MaGV AND b.Thu=tb.Thu AND b.Buoi=tb.Buoi AND b.Tiet=3) THEN 4 ELSE 0 END) +
            (CASE WHEN NOT EXISTS (SELECT 1 FROM BanSlot b WHERE b.MaGV=gc.MaGV AND b.Thu=tb.Thu AND b.Buoi=tb.Buoi AND b.Tiet=4) THEN 8 ELSE 0 END) +
            (CASE WHEN NOT EXISTS (SELECT 1 FROM BanSlot b WHERE b.MaGV=gc.MaGV AND b.Thu=tb.Thu AND b.Buoi=tb.Buoi AND b.Tiet=5) THEN 16 ELSE 0 END)
            AS BitMask
        FROM GVCanXep gc CROSS JOIN ThuBuoi tb
    ),
    -- Bang tra "so cap tiet lien ke toi da" cho 32 to hop 5-bit (tinh san bang thuat toan greedy quet
    -- trai->phai, xem giai thich trong tin nhan thiet ke — khong doi duoc bang tay, chi tinh 1 lan).
    MaskPairs AS (
        SELECT BitMask, Pairs FROM (VALUES
            (0,0),(1,0),(2,0),(3,1),(4,0),(5,0),(6,1),(7,1),(8,0),(9,0),(10,0),(11,1),(12,1),(13,1),(14,1),(15,2),
            (16,0),(17,0),(18,0),(19,1),(20,0),(21,0),(22,1),(23,1),(24,1),(25,1),(26,1),(27,2),(28,1),(29,1),(30,2),(31,2)
        ) x(BitMask, Pairs)
    ),
    KhaDung AS (
        SELECT m.MaGV, SUM(mp.Pairs) AS SoCapKhaDung
        FROM Mask m INNER JOIN MaskPairs mp ON mp.BitMask = m.BitMask
        GROUP BY m.MaGV
    )
    INSERT INTO @DsGV (MaGV, SoCapCanXep, SoCapKhaDung, TyLeCang)
    SELECT gc.MaGV, gc.SoCapCanXep, ISNULL(kd.SoCapKhaDung, 0),
           gc.SoCapCanXep / NULLIF(ISNULL(kd.SoCapKhaDung, 0), 0)
    FROM GVCanXep gc
    LEFT JOIN KhaDung kd ON kd.MaGV = gc.MaGV
    WHERE NOT EXISTS (SELECT 1 FROM tblTKB_TietDoiTuanTuDaXuLy dxl WHERE dxl.RunID = @RunID AND dxl.MaGV = gc.MaGV AND dxl.Khoi = @Khoi);

    -- Case ve mat toan hoc KHONG DU CHO (SoCapCanXep > SoCapKhaDung, ke ca SoCapKhaDung=0) — bao NGAY,
    -- khong can cho solver chay moi biet — day la ung vien cho co che "vi pham co kiem soat" (chua
    -- trien khai, xem memory tkb-vi-pham-co-backup), hien tai chi GHI NHAN de nguoi dung biet som.
    INSERT INTO tblTKB_TietDoiKhongDuCho (RunID, MaGV, Khoi, SoCapCanXep, SoCapKhaDung, ThoiGian)
    SELECT @RunID, d.MaGV, @Khoi, d.SoCapCanXep, d.SoCapKhaDung, SYSUTCDATETIME()
    FROM @DsGV d
    WHERE d.SoCapCanXep > d.SoCapKhaDung
      AND NOT EXISTS (SELECT 1 FROM tblTKB_TietDoiKhongDuCho w WHERE w.RunID = @RunID AND w.MaGV = d.MaGV AND w.Khoi = @Khoi);

    DECLARE @TongSoGV INT = (SELECT COUNT(*) FROM @DsGV);
    DECLARE @ViTri INT = 1, @GVDangXu VARCHAR(9), @TrangThaiGV NVARCHAR(50), @WaitedSecs INT, @DaXuLyLanNay INT = 0;

    WHILE @ViTri <= @TongSoGV AND @DaXuLyLanNay < @SoGVMoiLan
    BEGIN
        -- GV cang CANG (TyLeCang cao — hep gio hoac fan-out nhieu lop) xu ly TRUOC. GV KhaDung=0 (khong
        -- co cap nao) van duoc xep cuoi hang cua nhom TyLeCang cao nhat (NULL -> coi nhu vo cung cang).
        SELECT TOP 1 @GVDangXu = MaGV FROM @DsGV WHERE DaXuLy = 0
        ORDER BY CASE WHEN TyLeCang IS NULL THEN 999999 ELSE TyLeCang END DESC;

        IF @GVDangXu IS NULL BREAK;

        EXEC spAPI_TkbChayAuto @Khoi = @Khoi, @HocKy = @HocKy, @MaxSecs = @MaxSecsPerGV,
             @TuanHienTai = @TuanHienTai, @RunIDDangXay = @RunID, @ChiGV = @GVDangXu,
             @ChiMonDoi = 1, @ChiCumTach = @ChiCumTach, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;

        SET @TrangThaiGV = N'DangChay'; SET @WaitedSecs = 0;
        WHILE @TrangThaiGV = N'DangChay' AND @WaitedSecs < (@MaxSecsPerGV + 60)
        BEGIN
            WAITFOR DELAY '00:00:01';
            SET @WaitedSecs = @WaitedSecs + 1;
            EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
            SELECT @TrangThaiGV = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
        END

        -- Khoa NGAY ket qua vua giai cho GV nay (chi trong pham vi @Khoi cua round nay) truoc khi sang
        -- GV ke tiep — dam bao GV xu ly sau khong the "danh mat" slot cua GV nay.
        INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
        SELECT k.ID FROM tblTKB_KetQuaXep k
        INNER JOIN tblTKB_Lop l ON l.MaLop = k.MaLop
        LEFT JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
        WHERE k.RunID = @RunID AND k.MaGV = @GVDangXu AND kh.KetQuaXepID IS NULL
          AND (@Khoi = '' OR l.Khoi IN (SELECT value FROM STRING_SPLIT(@Khoi, ',')));

        UPDATE @DsGV SET DaXuLy = 1 WHERE MaGV = @GVDangXu;
        INSERT INTO tblTKB_TietDoiTuanTuDaXuLy (RunID, MaGV, Khoi, ThoiGian) VALUES (@RunID, @GVDangXu, @Khoi, SYSUTCDATETIME());
        SET @ViTri = @ViTri + 1;
        SET @DaXuLyLanNay = @DaXuLyLanNay + 1;
    END

    IF @ViTri <= @TongSoGV
    BEGIN
        SET @TrangThaiRa = 'ConTiepTuc';
        SELECT @RunID AS RunID, N'ConTiepTuc' AS TrangThaiCuoiCung,
               @TongSoGV - @ViTri + 1 AS SoGVConLai,
               (SELECT COUNT(*) FROM tblTKB_TietDoiKhongDuCho WHERE RunID=@RunID AND Khoi=@Khoi) AS SoGVKhongDuCho;
        RETURN;
    END

    SET @TrangThaiRa = 'HoanTat';
    SELECT @RunID AS RunID, N'HoanTat' AS TrangThaiCuoiCung, 0 AS SoGVConLai,
           (SELECT COUNT(*) FROM tblTKB_TietDoiKhongDuCho WHERE RunID=@RunID AND Khoi=@Khoi) AS SoGVKhongDuCho;
END
