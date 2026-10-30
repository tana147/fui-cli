CREATE PROCEDURE spAPI_TkbChayNhanh
    @RunID INT,
    @TuanHienTai INT,
    @HocKy VARCHAR(4),
    @MaxSecs INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-10-06 (muc tieu nguoi dung: auto >= 90%, nhanh, 10% con lai sap tay): PIPELINE NHANH "giai gop theo cap",
    -- thay 9 Round tuan tu (1-2 gio). Do thu RunID 1462 tuan 8: 98,2% trong ~14 phut.
    --   Buoc 1  khoa cung (Round 1: SH, HDTN1, chao co...)
    --   Buoc 2  cum tach khoi 10-12 (1 job CP-SAT)
    --   Buoc 3  khoa 10-12 roi giai GOP phan con lai khoi 10-12 (1 job)
    --   Buoc 4  khoa 10-12 roi xep TRUOC cac mon tiet doi khoi 06-09 (@ChiMonDoi=1, 1 job)
    --   Buoc 5  khoa tiet doi roi giai GOP phan con lai khoi 06-09 (1 job) — THCS/THPT dung chung 51 GV nen giai sau THPT
    --   Buoc 6  xep TRUOC cac mon tiet doi tieu hoc 01-05 (@ChiMonDoi=1, 1 job)
    --   Buoc 7  khoa roi giai GOP phan con lai tieu hoc (1 job) — GV da xep o buoc truoc tu dong thanh cam cung
    --   Buoc 8  hoan tat
    -- 2026-10-06 (v2): them buoc "tiet doi truoc" cho cap 2 va tieu hoc. Ly do (RunID 1462, v1 4 buoc): 46/58 tiet
    -- con thieu la mon tiet doi (ENG2 khoi 6-9: 34, TANN/TAVN/BOI tieu hoc: 12) — lop chi con 1-3 o trong roi rac,
    -- khong con 2 o lien nhau. Xep "do to" (cap tiet) truoc, "do nho" (tiet don) lap khe sau — cung ket luan Round 1.6 cu.
    -- Lan chay v1 da xong (KetThuc co gia tri) KHONG duoc chay tiep du Buoc cu = 6 (< 8 cua v2).
    -- MAY TRANG THAI luu o tblTKB_ChayNhanh: UI goi lai SP nay moi ~5 giay voi @RunID — moi lan goi: neu job
    -- dang chay thi chi cap nhat trang thai; neu job xong thi tu khoi dong buoc ke tiep. Moi lan goi ngan
    -- (khong WAITFOR) nen khong vuong gioi han thoi gian HTTP; tai lai trang van chay tiep dung buoc (state o DB).
    -- Goi lan dau voi @RunID NULL/0 + @TuanHienTai de tao RunID moi.
    -- Chi tra 1 result set (tAPI chi doc tap dau): moi SP con co result set deu duoc nuot (INSERT-EXEC / @ChiCapNhat=1).
    SET @HocKy = ISNULL(NULLIF(@HocKy, ''), 'HK1');
    IF @MaxSecs IS NULL SET @MaxSecs = 300;
    IF @MaxSecs < 60 SET @MaxSecs = 60;
    IF @MaxSecs > 600 SET @MaxSecs = 600;

    DECLARE @Buoc INT, @TT NVARCHAR(50), @Tuan INT, @Max INT, @MaxDoi INT, @Loi NVARCHAR(500) = NULL;
    DECLARE @KhoiTruoc VARCHAR(50), @MonTruoc VARCHAR(400), @GVHep VARCHAR(500);

    IF ISNULL(@RunID, 0) = 0
    BEGIN
        IF @TuanHienTai IS NULL
        BEGIN
            SELECT CAST(NULL AS INT) AS RunID, 0 AS Buoc, N'Chưa chọn tuần' AS TenBuoc, N'Loi' AS TrangThai,
                   0 AS GiayBuoc, 0 AS GiayTong, 0 AS TongCan, 0 AS DaXep, CAST(0 AS DECIMAL(5,1)) AS PhanTram, N'' AS TrangThaiSolver;
            RETURN;
        END
        -- 2026-10-10 (ke hoach TKB buoc 2): kiem tra du lieu tuan truoc khi chay — co muc LOI thi khong tao RunID, bao loi.
        DECLARE @kt TABLE (MucDo VARCHAR(10), Nhom NVARCHAR(50), DoiTuong NVARCHAR(100), MoTa NVARCHAR(400), GoiY NVARCHAR(300));
        INSERT INTO @kt EXEC spAPI_TkbKiemTraDuLieuTuan @Tuan = @TuanHienTai, @sys_UserID = @sys_UserID;
        IF EXISTS (SELECT 1 FROM @kt WHERE MucDo = 'LOI')
        BEGIN
            SELECT CAST(NULL AS INT) AS RunID, 0 AS Buoc,
                   N'Dữ liệu tuần ' + CAST(@TuanHienTai AS NVARCHAR(5)) + N' có ' + CAST((SELECT COUNT(*) FROM @kt WHERE MucDo = 'LOI') AS NVARCHAR(5))
                   + N' lỗi nên chưa chạy. Ví dụ: ' + (SELECT TOP 1 MoTa FROM @kt WHERE MucDo = 'LOI' ORDER BY Nhom, DoiTuong)
                   + N' Xem đủ danh sách ở tab Tuần mới.' AS TenBuoc,
                   N'Loi' AS TrangThai, 0 AS GiayBuoc, 0 AS GiayTong, 0 AS TongCan, 0 AS DaXep, CAST(0 AS DECIMAL(5,1)) AS PhanTram, N'' AS TrangThaiSolver;
            RETURN;
        END
        DECLARE @r TABLE (RunID INT, TongSoTiet INT, SoTietDaKhoa INT, PhanTramDaKhoa DECIMAL(9,2));
        INSERT INTO @r EXEC spAPI_TkbRound1_KhoaCung @Khoi = '', @HocKy = @HocKy, @TuanHienTai = @TuanHienTai, @sys_UserID = @sys_UserID;
        SELECT @RunID = RunID FROM @r;

        INSERT INTO tblTKB_ChayNhanh (RunID, TuanHienTai, HocKy, MaxSecs, Buoc, BatDau, BuocBatDau, NguoiChay)
        VALUES (@RunID, @TuanHienTai, @HocKy, @MaxSecs, 2, SYSUTCDATETIME(), SYSUTCDATETIME(), @sys_UserID);

        EXEC spAPI_TkbChayAuto @Khoi = '10,11,12', @HocKy = @HocKy, @MaxSecs = 180, @TuanHienTai = @TuanHienTai,
             @RunIDDangXay = @RunID, @ChiCumTach = 1, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
    END
    ELSE
    BEGIN
        SELECT @Buoc = Buoc, @Tuan = TuanHienTai, @Max = MaxSecs, @HocKy = HocKy FROM tblTKB_ChayNhanh WHERE RunID = @RunID;
        -- Buoc chi xep tiet doi nho hon nhieu (chi vai mon) -> nua thoi gian, toi thieu 90 giay.
        SET @MaxDoi = CASE WHEN @Max / 2 < 90 THEN 90 ELSE @Max / 2 END;
        IF @Buoc IS NULL
        BEGIN
            SELECT @RunID AS RunID, 0 AS Buoc, N'RunID này không chạy bằng chế độ nhanh' AS TenBuoc, N'Loi' AS TrangThai,
                   0 AS GiayBuoc, 0 AS GiayTong, 0 AS TongCan, 0 AS DaXep, CAST(0 AS DECIMAL(5,1)) AS PhanTram, N'' AS TrangThaiSolver;
            RETURN;
        END

        IF @Buoc < 9 AND NOT EXISTS (SELECT 1 FROM tblTKB_ChayNhanh WHERE RunID = @RunID AND KetThuc IS NOT NULL)
        BEGIN
            SELECT @TT = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
            -- Chi hoi trang thai khi job da co JobID (LoiChiTiet): ngay sau khi 1 lan goi khac vua "gianh" buoc va dang
            -- khoi dong solver, TrangThai da = DangChay nhung JobID chua ghi -> httpCall voi URL NULL se loi. Khi do coi
            -- nhu van dang chay, lan goi sau hoi lai.
            IF @TT = N'DangChay' AND EXISTS (SELECT 1 FROM tblTKB_ChayAutoLog WHERE RunID = @RunID AND LoiChiTiet IS NOT NULL)
            BEGIN
                -- Thu thap ket qua neu job solver vua xong (ghi vao tblTKB_KetQuaXep).
                EXEC spAPI_TkbChayAutoTrangThai @RunID = @RunID, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                SELECT @TT = TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
            END

            IF @TT IS NULL OR @TT <> N'DangChay'
            BEGIN
                -- KHOA LAC QUAN: chi lan goi nao "gianh" duoc chuyen buoc (Buoc cu -> moi) moi duoc khoi dong buoc moi —
                -- tranh 2 lan goi chong nhau (dong ho UI, 2 tab) cung thay job xong va khoi dong 1 buoc 2 lan.
                -- Dong thoi dat ngay TrangThai='DangChay' de lan goi chen vao giua khong tuong buoc moi da xong.
                DECLARE @BuocCu INT = @Buoc, @Gianh INT;
                UPDATE tblTKB_ChayNhanh
                   SET Buoc = @BuocCu + 1, BuocBatDau = SYSUTCDATETIME(),
                       KetThuc = CASE WHEN @BuocCu + 1 >= 9 THEN SYSUTCDATETIME() ELSE NULL END,
                       NhatKy = LEFT(ISNULL(NhatKy, N'') + N'B' + CAST(@BuocCu AS NVARCHAR(2)) + N'=' + ISNULL(@TT, N'?')
                              + N'(' + CAST(DATEDIFF(SECOND, BuocBatDau, SYSUTCDATETIME()) AS NVARCHAR(10)) + N's) ', 2000)
                 WHERE RunID = @RunID AND Buoc = @BuocCu;
                SET @Gianh = @@ROWCOUNT;
                IF @Gianh = 1 AND @BuocCu IN (2, 3, 4, 5, 6)
                    UPDATE tblTKB_ChayAutoLog SET TrangThai = N'DangChay' WHERE RunID = @RunID;

                IF @Gianh = 1
                BEGIN
                    DECLARE @k TABLE (SoTietDaKhoa INT);
                    -- LAP GIO HOP (2026-10-09, doi chieu TKB that tuan 11 — RunID 1541 thieu 01A/01F TV): gio hop GVCN tieu hoc
                    -- (vd khoi 1 T6 sang t3-4) ca 7 lop phai hoc GV bo mon cung luc; nguoi xep tay lap 7/7 (2 GV GDTC song song,
                    -- doi TA GVVN dat dung doi gio hop), may lap 5/7 -> lo trong -> tiet GVCN het cho. Pha phu chen TRUOC buoc 5
                    -- (xep truoc tieu hoc): HopPha NULL -> chay rieng cac mon bo mon tieu hoc (GV khac GVCN), phat o hop trong
                    -- (OChuyenBatBuoc), lui Buoc ve 5 de cho job; HopPha 1 -> chi giu tiet roi vao gio hop (+ nua con lai cua doi),
                    -- xoa phan con lai, roi chay buoc 5 binh thuong.
                    IF @BuocCu = 5
                    BEGIN
                        DECLARE @HopPha TINYINT, @HopId INT, @MonChuyenTH VARCHAR(100), @GiuHop INT;
                        SELECT @HopPha = HopPha, @HopId = HopIdTruoc FROM tblTKB_ChayNhanh WHERE RunID = @RunID;
                        SELECT @MonChuyenTH = STRING_AGG(x.MaMon, ',') FROM (
                            SELECT DISTINCT pc.MaMon FROM tblTKB_PhanCongGiangDay pc INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
                            WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND l.Khoi IN ('01','02','03','04','05') AND LEN(l.MaLop) = 3
                              AND pc.MaGV <> ISNULL(l.GVCN, '')) x;
                        IF @HopPha IS NULL AND @MonChuyenTH IS NOT NULL AND LEN(@MonChuyenTH) <= 100
                        BEGIN
                            UPDATE tblTKB_ChayNhanh SET Buoc = 5, HopPha = 1, HopIdTruoc = (SELECT ISNULL(MAX(ID), 0) FROM tblTKB_KetQuaXep)
                            WHERE RunID = @RunID;
                            EXEC spAPI_TkbChayAuto @Khoi = '01,02,03,04,05', @HocKy = @HocKy, @MaxSecs = 180, @TuanHienTai = @Tuan,
                                 @RunIDDangXay = @RunID, @ChiMon = @MonChuyenTH, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                            SET @BuocCu = 0;   -- khong chay nhanh dispatch ben duoi o lan goi nay
                        END
                        ELSE IF @HopPha = 1
                        BEGIN
                            ;WITH OHop AS (
                                SELECT l.MaLop, h.Thu, h.Buoi, h.Tiet
                                FROM tblTKB_Lop l CROSS APPLY dbo.fnTkbLichHopGV(@Tuan) h
                                WHERE h.MaGV = l.GVCN AND h.LoaiNhom <> 'KhoiCap23SH' AND h.Tiet <= 4
                                  AND l.Enable = 1 AND l.Khoi IN ('01','02','03','04','05') AND LEN(l.MaLop) = 3
                            )
                            -- giu tiet nam trong gio hop cua lop (lop TG theo lop goc), va nua con lai cua doi (cung lop/mon/buoi, tiet ke ben)
                            DELETE k FROM tblTKB_KetQuaXep k
                            WHERE k.RunID = @RunID AND k.ID > @HopId
                              AND k.MaMon IN (SELECT value FROM STRING_SPLIT(@MonChuyenTH, ','))
                              AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k2
                                              INNER JOIN OHop o2 ON k2.MaLop LIKE o2.MaLop + '%' AND o2.Thu = k2.Thu AND o2.Buoi = k2.Buoi AND o2.Tiet = k2.Tiet
                                              WHERE k2.RunID = @RunID AND k2.ID > @HopId AND k2.MaLop = k.MaLop AND k2.MaMon = k.MaMon
                                                AND k2.Thu = k.Thu AND k2.Buoi = k.Buoi AND ABS(k2.Tiet - k.Tiet) <= 1);
                            SELECT @GiuHop = COUNT(*) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND ID > @HopId
                              AND MaMon IN (SELECT value FROM STRING_SPLIT(@MonChuyenTH, ','));
                            UPDATE tblTKB_ChayNhanh SET HopPha = 2,
                                   NhatKy = LEFT(ISNULL(NhatKy, N'') + N'[hop:' + CAST(@GiuHop AS NVARCHAR(10)) + N' tiet bo mon] ', 2000)
                            WHERE RunID = @RunID;
                        END
                    END
                    IF @BuocCu = 2
                    BEGIN
                        INSERT INTO @k EXEC spAPI_TkbKhoaKetQuaKhoi1012 @RunID = @RunID, @sys_UserID = @sys_UserID;
                        EXEC spAPI_TkbChayAuto @Khoi = '10,11,12', @HocKy = @HocKy, @MaxSecs = 240, @TuanHienTai = @Tuan,
                             @RunIDDangXay = @RunID, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                    END
                    ELSE IF @BuocCu IN (3, 5)
                    BEGIN
                        -- "XEP TRUOC" (v3, 2026-10-06): moi mon co rang buoc PHAN BO cung trong tuan — bat buoc tiet doi
                        -- (BatBuocXepDoi), pattern theo khoi (TV...), gioi han so tiet/ngay (MaxTietMoiNgay, vd TOAN tieu hoc
                        -- 1 tiet/ngay = can 5 ngay khac nhau) — ap dung cho NHOM KHOI cua buoc nay. Lay tu danh muc, khong
                        -- ghi cung ten mon. v4: gom ca HDTN1_Pattern (phan HDTN1 linh hoat con lai sau Round 1 — RunID 1465 thieu
                        -- 12 tiet HDTN1 tieu hoc vi GVCN da kin lich TOAN/TV xep truoc). Ly do: v2 chi xep truoc tiet doi -> TOAN tieu hoc bi TV/tiet doi chiem het ngay,
                        -- thieu 16 tiet (RunID 1464); v1 khong xep truoc -> ENG2 khoi 6-9 thieu 34 tiet (RunID 1462).
                        SET @KhoiTruoc = CASE WHEN @BuocCu = 3 THEN '06,07,08,09' ELSE '01,02,03,04,05' END;
                        IF @BuocCu = 3
                            INSERT INTO @k EXEC spAPI_TkbKhoaKetQuaKhoi1012 @RunID = @RunID, @sys_UserID = @sys_UserID;
                        SELECT @MonTruoc = STRING_AGG(m.MaMon, ',')
                        FROM (
                            SELECT DISTINCT pc.MaMon
                            FROM tblTKB_PhanCongGiangDay pc
                            INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
                            WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
                              AND l.Khoi IN (SELECT value FROM STRING_SPLIT(@KhoiTruoc, ','))
                              AND (EXISTS (SELECT 1 FROM tblTKB_MonHoc mh WHERE mh.MaMon = pc.MaMon AND mh.BatBuocXepDoi = 1)
                                   OR EXISTS (SELECT 1 FROM tblTKB_MonQuyTac mq
                                              WHERE mq.MaMon = pc.MaMon AND mq.Enable = 1
                                                AND (mq.LoaiQuyTac LIKE '%[_]Pattern' OR mq.LoaiQuyTac = 'MaxTietMoiNgay')
                                                AND (mq.Khoi IS NULL OR mq.Khoi = l.Khoi)))
                        ) m;
                        -- 2026-10-07: GV HEP GIO khoi 06-09 (so o ranh trong khung 40 o - lich ban tuan - hop - tiet da khoa
                        -- o buoc truoc, tru so tiet phai day <= 4) -> dua THEM vao buoc xep truoc (@ThemGV). Phan tich T8-T11:
                        -- Van thinh giang (Kieu Oanh 8/9 lan, Van Tu 7/9), CN Nguyet Minh (7/9) thieu vi o hiem bi mon khac khoa truoc.
                        SET @GVHep = NULL;
                        IF @BuocCu = 3
                        BEGIN
                            ;WITH PCx AS (
                                SELECT pc.MaGV, SUM(pc.SoTietChuanTuan) AS Tai
                                FROM tblTKB_PhanCongGiangDay pc INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
                                WHERE pc.Enable = 1 AND pc.HocKy = @HocKy AND l.Khoi IN ('06','07','08','09') AND pc.MaGV LIKE 'NV%'
                                  AND (pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu) AND (pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
                                  AND (pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
                                GROUP BY pc.MaGV
                            ),
                            Ox AS (SELECT t.Thu, b.Buoi, x.Tiet FROM (VALUES(2),(3),(4),(5),(6)) t(Thu) CROSS JOIN (VALUES('Sang'),('Chieu')) b(Buoi) CROSS JOIN (VALUES(1),(2),(3),(4)) x(Tiet)),
                            Ban AS (
                                SELECT g.MaGV, g.Thu, bb.Buoi, tt.Tiet FROM tblTKB_GVCamTuyetDoi_Tuan g
                                CROSS APPLY (SELECT Buoi FROM (VALUES('Sang'),('Chieu')) x(Buoi) WHERE ISNULL(g.Buoi,'') = '' OR g.Buoi = x.Buoi) bb
                                CROSS APPLY (SELECT Tiet FROM (VALUES(1),(2),(3),(4)) y(Tiet) WHERE g.Tiet IS NULL OR g.Tiet = y.Tiet) tt
                                WHERE g.Tuan = @Tuan
                                UNION SELECT h.MaGV, h.Thu, h.Buoi, h.Tiet FROM dbo.fnTkbLichHopGV(@Tuan) h
                                UNION SELECT k.MaGV, k.Thu, k.Buoi, k.Tiet FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID AND k.MaGV IS NOT NULL
                            )
                            SELECT @GVHep = STRING_AGG(CAST(p.MaGV AS VARCHAR(MAX)), ',')
                            FROM PCx p
                            WHERE (SELECT COUNT(*) FROM Ox o WHERE NOT EXISTS (SELECT 1 FROM Ban b WHERE b.MaGV = p.MaGV AND b.Thu = o.Thu AND b.Buoi = o.Buoi AND b.Tiet = o.Tiet)) - p.Tai <= 4;
                            IF LEN(@GVHep) > 500 SET @GVHep = LEFT(@GVHep, 490);
                        END
                        -- @ChiMon cua spAPI_TkbChayAuto la VARCHAR(100): danh sach qua dai -> quay ve loc tiet doi co san.
                        IF @MonTruoc IS NULL OR LEN(@MonTruoc) > 100
                            EXEC spAPI_TkbChayAuto @Khoi = @KhoiTruoc, @HocKy = @HocKy, @MaxSecs = @MaxDoi, @TuanHienTai = @Tuan,
                                 @RunIDDangXay = @RunID, @ChiMonDoi = 1, @ThemGV = @GVHep, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                        ELSE
                            EXEC spAPI_TkbChayAuto @Khoi = @KhoiTruoc, @HocKy = @HocKy, @MaxSecs = @MaxDoi, @TuanHienTai = @Tuan,
                                 @RunIDDangXay = @RunID, @ChiMon = @MonTruoc, @ThemGV = @GVHep, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                        UPDATE tblTKB_ChayNhanh SET NhatKy = LEFT(ISNULL(NhatKy, N'') + N'[truoc:' + ISNULL(@MonTruoc, N'tietdoi') + ISNULL(N' +GVhep:' + CAST((LEN(@GVHep) - LEN(REPLACE(@GVHep, ',', '')) + 1) AS NVARCHAR(5)), N'') + N'] ', 2000)
                        WHERE RunID = @RunID;
                    END
                    ELSE IF @BuocCu = 4
                    BEGIN
                        -- Khoa khoi 1-9: luc nay khoi 6-9 moi chi co tiet doi vua xep, tieu hoc chi co dong khoa cung Round 1.
                        INSERT INTO @k EXEC spAPI_TkbKhoaKetQuaTietDoiCap12 @RunID = @RunID, @sys_UserID = @sys_UserID;
                        EXEC spAPI_TkbChayAuto @Khoi = '06,07,08,09', @HocKy = @HocKy, @MaxSecs = @Max, @TuanHienTai = @Tuan,
                             @RunIDDangXay = @RunID, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                    END
                    ELSE IF @BuocCu = 6
                    BEGIN
                        INSERT INTO @k EXEC spAPI_TkbKhoaKetQuaTietDoiCap12 @RunID = @RunID, @sys_UserID = @sys_UserID;
                        EXEC spAPI_TkbChayAuto @Khoi = '01,02,03,04,05', @HocKy = @HocKy, @MaxSecs = @Max, @TuanHienTai = @Tuan,
                             @RunIDDangXay = @RunID, @KhongChoSkip = 0, @ChiCapNhat = 1, @sys_UserID = @sys_UserID;
                    END
                    ELSE IF @BuocCu = 7
                    BEGIN
                        -- Buoc 7/7 "VA DOI CHO CUC BO" v2 (2026-10-10, thi nghiem RunID 1567/1563): vung mo dan theo vong (1: lop thieu + khoi
                        -- + lop GV thieu day; 2: + lop GV lien doi + khoi; 3: ca cap), luon kem tron cum tach + lop TG, NEO tung tiet vao cho cu
                        -- (phat 60) -> chi doi vai tiet de lap lo. Xem spTkbVaCucBo_BatDau. Khong con gioi han khoi < 10.
                        DECLARE @VaBD BIT = 0;
                        EXEC spTkbVaCucBo_BatDau @RunID = @RunID, @Vong = 1, @Tuan = @Tuan, @HocKy = @HocKy, @MaxSecs = @MaxDoi,
                             @sys_UserID = @sys_UserID, @DaBatDau = @VaBD OUTPUT;
                        IF @VaBD = 0
                        BEGIN
                            UPDATE tblTKB_ChayNhanh SET Buoc = 9, KetThuc = SYSUTCDATETIME(), NhatKy = LEFT(ISNULL(NhatKy, N'') + N'[va:khong con thieu] ', 2000) WHERE RunID = @RunID;
                            DECLARE @dg0 TABLE (Khoi NVARCHAR(20), TongCan INT, DaXep INT, Thieu INT, PhanTram DECIMAL(5,1), Thu INT);
                            INSERT INTO @dg0 EXEC spAPI_TkbDanhGiaRun @RunID = @RunID, @HocKy = @HocKy, @TuanHienTai = @Tuan, @Moc = 'NHANH', @sys_UserID = @sys_UserID;
                        END
                    END
                    ELSE IF @BuocCu = 8
                    BEGIN
                        -- Thu ket qua 1 vong va: khong tot hon (it tiet that hon hoac bang) -> khoi phuc ban sao; tot hon -> giu + khoa.
                        -- Con thieu va vong < 3 -> mo vong ke tiep (vung rong hon), lui Buoc ve 8 de cho job.
                        DECLARE @VaLop8 VARCHAR(2000), @VaTruoc8 INT, @VaSau INT, @BanSao8 INT, @Vong8 TINYINT, @Doi8 INT = 0;
                        SELECT @VaLop8 = VaLop, @VaTruoc8 = VaTruoc, @BanSao8 = VaBanSao, @Vong8 = ISNULL(VaVong, 1) FROM tblTKB_ChayNhanh WHERE RunID = @RunID;
                        IF @VaLop8 IS NOT NULL AND @BanSao8 IS NOT NULL
                        BEGIN
                            SELECT @VaSau = COUNT(*) FROM tblTKB_KetQuaXep k
                            WHERE k.RunID = @RunID AND k.MaLop IN (SELECT value FROM STRING_SPLIT(@VaLop8, ',')) AND k.MaMon <> 'HOP'
                              AND NOT EXISTS (SELECT 1 FROM tblTKB_CumTach c WHERE c.MaCumTach = k.MaMon);
                            SELECT @Doi8 = COUNT(*) FROM tblTKB_KetQuaXep k
                            WHERE k.RunID = @RunID AND k.MaLop IN (SELECT value FROM STRING_SPLIT(@VaLop8, ',')) AND k.MaMon <> 'HOP'
                              AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep b WHERE b.RunID = @BanSao8 AND b.MaLop = k.MaLop AND b.MaMon = k.MaMon
                                              AND b.Thu = k.Thu AND b.Buoi = k.Buoi AND b.Tiet = k.Tiet);
                            IF @VaSau <= @VaTruoc8
                            BEGIN
                                DELETE kk FROM tblTKB_KetQuaXep_Khoa kk INNER JOIN tblTKB_KetQuaXep k ON k.ID = kk.KetQuaXepID
                                WHERE k.RunID = @RunID AND k.MaLop IN (SELECT value FROM STRING_SPLIT(@VaLop8, ','));
                                DELETE FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop IN (SELECT value FROM STRING_SPLIT(@VaLop8, ','));
                                INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro)
                                SELECT @RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong, XoayTro FROM tblTKB_KetQuaXep WHERE RunID = @BanSao8;
                            END
                            INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
                            SELECT k.ID FROM tblTKB_KetQuaXep k
                            WHERE k.RunID = @RunID AND k.MaLop IN (SELECT value FROM STRING_SPLIT(@VaLop8, ','))
                              AND NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa kk WHERE kk.KetQuaXepID = k.ID);
                            DELETE FROM tblTKB_KetQuaXep WHERE RunID = @BanSao8;
                            UPDATE tblTKB_ChayAutoLog SET Enable = 0 WHERE RunID = @BanSao8;
                            UPDATE tblTKB_ChayNhanh
                               SET VaLop = NULL, VaBanSao = NULL,
                                   NhatKy = LEFT(ISNULL(NhatKy, N'') + CASE WHEN @VaSau <= @VaTruoc8 THEN N'[va' + CAST(@Vong8 AS NVARCHAR(2)) + N':khong tot hon -> khoi phuc] '
                                                 ELSE N'[va' + CAST(@Vong8 AS NVARCHAR(2)) + N':+' + CAST(@VaSau - @VaTruoc8 AS NVARCHAR(5)) + N' tiet, doi ' + CAST(@Doi8 AS NVARCHAR(5)) + N'] ' END, 2000)
                            WHERE RunID = @RunID;
                            -- Vong ke tiep neu con thieu
                            IF @Vong8 < 3
                            BEGIN
                                DECLARE @VaBD8 BIT = 0, @V8 TINYINT = @Vong8 + 1;
                                UPDATE tblTKB_ChayNhanh SET Buoc = 8, KetThuc = NULL, BuocBatDau = SYSUTCDATETIME() WHERE RunID = @RunID;
                                EXEC spTkbVaCucBo_BatDau @RunID = @RunID, @Vong = @V8, @Tuan = @Tuan, @HocKy = @HocKy, @MaxSecs = @Max,
                                     @sys_UserID = @sys_UserID, @DaBatDau = @VaBD8 OUTPUT;
                                IF @VaBD8 = 0
                                    UPDATE tblTKB_ChayNhanh SET Buoc = 9, KetThuc = SYSUTCDATETIME() WHERE RunID = @RunID;
                            END
                        END
                        IF NOT EXISTS (SELECT 1 FROM tblTKB_ChayNhanh WHERE RunID = @RunID AND Buoc = 8)
                        BEGIN
                            DECLARE @dg TABLE (Khoi NVARCHAR(20), TongCan INT, DaXep INT, Thieu INT, PhanTram DECIMAL(5,1), Thu INT);
                            INSERT INTO @dg EXEC spAPI_TkbDanhGiaRun @RunID = @RunID, @HocKy = @HocKy, @TuanHienTai = @Tuan, @Moc = 'NHANH', @sys_UserID = @sys_UserID;
                        END
                    END
                END
            END
        END
    END

    -- Ket qua: so tiet da xep / nhu cau (MIN theo lop-mon, giong spAPI_TkbDanhGiaRun).
    SELECT @Buoc = Buoc, @Tuan = TuanHienTai FROM tblTKB_ChayNhanh WHERE RunID = @RunID;
    DECLARE @TongCan INT, @DaXep INT;
    SELECT @TongCan = SUM(d.Can), @DaXep = SUM(CASE WHEN ISNULL(x.Xep, 0) < d.Can THEN ISNULL(x.Xep, 0) ELSE d.Can END)
    FROM (
        SELECT pc.MaLop, pc.MaMon, SUM(pc.SoTietChuanTuan) AS Can
        FROM tblTKB_PhanCongGiangDay pc
        WHERE pc.Enable = 1 AND pc.HocKy = @HocKy
          AND (@Tuan IS NULL OR pc.TuanApDungTu IS NULL OR @Tuan >= pc.TuanApDungTu)
          AND (@Tuan IS NULL OR pc.TuanApDungDen IS NULL OR @Tuan <= pc.TuanApDungDen)
          AND (@Tuan IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @Tuan % 2 = 0 THEN 1 ELSE 0 END)
        GROUP BY pc.MaLop, pc.MaMon
    ) d
    INNER JOIN tblTKB_Lop l ON l.MaLop = d.MaLop
    LEFT JOIN (SELECT MaLop, MaMon, COUNT(*) AS Xep FROM tblTKB_KetQuaXep WHERE RunID = @RunID GROUP BY MaLop, MaMon) x
        ON x.MaLop = d.MaLop AND x.MaMon = d.MaMon;

    -- 2026-10-09: chay xong -> dien phong co dinh theo lop-mon (tblTKB_PhongLopMon) 1 lan cho cac tiet chua co phong.
    IF EXISTS (SELECT 1 FROM tblTKB_ChayNhanh WHERE RunID = @RunID AND (KetThuc IS NOT NULL OR Buoc >= 9)
               AND ISNULL(NhatKy, N'') NOT LIKE N'%[[]phong]%')
    BEGIN
        DECLARE @gp TABLE (SoTietGanPhong INT, SoTietDoiPhongTrung INT);
        INSERT @gp EXEC spTkbGanPhongTheoLopMon @RunID = @RunID;
        UPDATE tblTKB_ChayNhanh SET NhatKy = LEFT(ISNULL(NhatKy, N'') + N'[phong] ', 2000) WHERE RunID = @RunID;
    END

    SELECT n.RunID, n.Buoc,
           CASE WHEN n.KetThuc IS NOT NULL THEN N'Hoàn tất'
                WHEN n.Buoc = 2 THEN N'Bước 1/7 — Cụm tách khối 10-12'
                WHEN n.Buoc = 3 THEN N'Bước 2/7 — Giải gộp khối 10-12'
                WHEN n.Buoc = 4 THEN N'Bước 3/7 — Môn ràng buộc chặt khối 6-9'
                WHEN n.Buoc = 5 THEN N'Bước 4/7 — Giải gộp khối 6-9'
                WHEN n.Buoc = 6 THEN N'Bước 5/7 — Môn ràng buộc chặt tiểu học'
                WHEN n.Buoc = 7 THEN N'Bước 6/7 — Giải gộp tiểu học'
                WHEN n.Buoc = 8 THEN N'Bước 7/7 — Vá cục bộ tiết còn thiếu'
                ELSE N'Hoàn tất' END AS TenBuoc,
           CASE WHEN n.KetThuc IS NOT NULL OR n.Buoc >= 9 THEN N'HoanTat' ELSE N'DangChay' END AS TrangThai,
           DATEDIFF(SECOND, n.BuocBatDau, ISNULL(n.KetThuc, SYSUTCDATETIME())) AS GiayBuoc,
           DATEDIFF(SECOND, n.BatDau, ISNULL(n.KetThuc, SYSUTCDATETIME())) AS GiayTong,
           ISNULL(@TongCan, 0) AS TongCan, ISNULL(@DaXep, 0) AS DaXep,
           CAST(100.0 * ISNULL(@DaXep, 0) / NULLIF(@TongCan, 0) AS DECIMAL(5, 1)) AS PhanTram,
           ISNULL((SELECT TrangThai FROM tblTKB_ChayAutoLog WHERE RunID = n.RunID), N'') AS TrangThaiSolver,
           n.TuanHienTai
    FROM tblTKB_ChayNhanh n WHERE n.RunID = @RunID;
END