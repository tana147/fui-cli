CREATE PROCEDURE spAPI_TkbChayAutoTrangThai
    @RunID INT,
    @XoayTroMacDinh TINYINT = NULL,
    -- SUA 2026-09-22 (phat hien qua chay that RunID 1337, Round 6): khi SP nay duoc goi TU BEN TRONG
    -- vong lap WAITFOR cua spAPI_TkbGiaiTietDoiTuanTu/GiaiLopThuongTuanTu (moi 5s, kiem tra job con
    -- 'DangChay' khong), va job VUA XONG dung luc goi (JobStatus='done'), SP nay TU NO tra ve 1 SELECT
    -- ket qua (dong 234 cu) — result set nay xuat hien SOM HON SELECT CUOI CUNG ma SP goi no dinh
    -- nghia, va tAPI/driver SQL CHI DOC RESULT SET DAU TIEN cua ca chuoi goi long nhau -> doc NHAM
    -- thanh ket qua cuoi cung cua ca API call (UI hien '⚠️ Khong xac dinh duoc trang thai tra ve') DU
    -- CONG VIEC PHIA SAU (khoa, ghi tracking) VAN CHAY TIEP VA THANH CONG BINH THUONG. Xac nhan bang
    -- cach chay truc tiep qua SQL: cung 1 lenh EXEC, cong cu doc ket qua tra ve dung shape cua SELECT
    -- 'done'-branch (RunID/TrangThai/KhaThi/ThongBao) nhung GV van duoc khoa/ghi tracking dung.
    -- @ChiCapNhat=1: chi CAP NHAT DB (khoa ket qua, ghi log...), KHONG SELECT gi ca — dung khi goi TU
    -- BEN TRONG 1 SP khac (khong can ket qua tra ve ngay, se tu doc lai DB sau). Mac dinh =0 (giu
    -- nguyen hanh vi cu cho moi noi goi khac, vd UI goi truc tiep qua tAPI can ket qua tra ve).
    @ChiCapNhat BIT = 0,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TrangThaiHienTai NVARCHAR(50), @JobID VARCHAR(50);
    SELECT @TrangThaiHienTai = TrangThai, @JobID = LoiChiTiet FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;

    IF @TrangThaiHienTai IS NULL
    BEGIN
        IF @ChiCapNhat = 0
        BEGIN
        SELECT @RunID AS RunID, N'KhongTonTai' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               NULL AS SoNhuCau, NULL AS SoSlotDaXep, NULL AS TietTrongLe, NULL AS SoGvKhongCoBuoiRanh,
               NULL AS SoLuotVuotTranTietNgay, NULL AS SoTietViPhamChaoCo, NULL AS SoLuotLechTrack, NULL AS SoTietShKhongKem,
               N'Không tìm thấy lần chạy này' AS ThongBao;
        END
        RETURN;
    END

    -- Đã xử lý xong từ lần poll trước (hoặc lỗi) -> trả thẳng, không gọi lại solver
    IF @TrangThaiHienTai <> N'DangChay'
    BEGIN
        IF @ChiCapNhat = 0
        BEGIN
        SELECT RunID, TrangThai, KhaThi, SoNhuCau, SoSlotDaXep, TietTrongLe, SoGvKhongCoBuoiRanh,
               SoLuotVuotTranTietNgay, SoTietViPhamChaoCo, SoLuotLechTrack, SoTietShKhongKem,
               (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = l.RunID) AS SoNhomKhongXepDuoc,
               CASE WHEN TrangThai = N'LoiGoiSolver' THEN LoiChiTiet ELSE NULL END AS ThongBao
        FROM tblTKB_ChayAutoLog l WHERE RunID = @RunID;
        END
        RETURN;
    END

    DECLARE @StatusResponse NVARCHAR(MAX);
    -- 2026-09-17: dong bo dia chi solver voi spAPI_TkbChayAuto — xem giai thich day du o do.
    SELECT @StatusResponse = dbo.httpCall('GET', 'http://192.168.100.249:8080/api/solve/status/' + @JobID, '', '');

    DECLARE @JobStatus NVARCHAR(20) = JSON_VALUE(@StatusResponse, '$.status');

    -- notfound (job that su khong con trong bo nho server, vd sau khi service bi kill/restart) la
    -- LOI THAT SU (job da mat, khong the poll lai duoc nua) -> ghi LoiGoiSolver nhu cu.
    -- Nhung ket noi tam thoi that bai (StatusResponse rong/loi mang) KHONG duoc ghi de len LoiChiTiet
    -- (dang giu JobID) — giu nguyen TrangThai=DangChay de lan poll sau con the thu lai bang JobID that.
    IF @JobStatus = 'notfound'
    BEGIN
        UPDATE tblTKB_ChayAutoLog
        SET ThoiGianKetThuc = SYSUTCDATETIME(), TrangThai = N'LoiGoiSolver', LoiChiTiet = ISNULL(@StatusResponse, N'Job không còn tồn tại trên server (có thể do service bị restart)')
        WHERE RunID = @RunID;

        IF @ChiCapNhat = 0
        BEGIN
        SELECT @RunID AS RunID, N'LoiGoiSolver' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               NULL AS SoNhuCau, NULL AS SoSlotDaXep, NULL AS TietTrongLe, NULL AS SoGvKhongCoBuoiRanh,
               NULL AS SoLuotVuotTranTietNgay, NULL AS SoTietViPhamChaoCo, NULL AS SoLuotLechTrack, NULL AS SoTietShKhongKem,
               ISNULL(@StatusResponse, N'Job không còn tồn tại trên server (có thể do service bị restart)') AS ThongBao;
        END
        RETURN;
    END

    IF @JobStatus IS NULL
    BEGIN
        -- Loi mang/timeout tam thoi khi goi httpCall — KHONG dong TrangThai, giu DangChay de poll lai
        -- duoc bang JobID (van con nguyen trong LoiChiTiet). Tranh mat JobID vinh vien nhu tung xay ra.
        IF @ChiCapNhat = 0
        BEGIN
        SELECT @RunID AS RunID, N'DangChay' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               NULL AS SoNhuCau, NULL AS SoSlotDaXep, NULL AS TietTrongLe, NULL AS SoGvKhongCoBuoiRanh,
               NULL AS SoLuotVuotTranTietNgay, NULL AS SoTietViPhamChaoCo, NULL AS SoLuotLechTrack, NULL AS SoTietShKhongKem,
               N'Tạm thời không kết nối được server — thử kiểm tra lại sau' AS ThongBao;
        END
        RETURN;
    END

    IF @JobStatus = 'running'
    BEGIN
        IF @ChiCapNhat = 0
        BEGIN
        SELECT RunID, TrangThai, KhaThi, SoNhuCau, SoSlotDaXep, TietTrongLe, SoGvKhongCoBuoiRanh,
               SoLuotVuotTranTietNgay, SoTietViPhamChaoCo, SoLuotLechTrack, SoTietShKhongKem, CAST(NULL AS NVARCHAR(500)) AS ThongBao
        FROM tblTKB_ChayAutoLog WHERE RunID = @RunID;
        END
        RETURN;
    END

    IF @JobStatus = 'error'
    BEGIN
        UPDATE tblTKB_ChayAutoLog
        SET ThoiGianKetThuc = SYSUTCDATETIME(), TrangThai = N'LoiSolver', LoiChiTiet = JSON_VALUE(@StatusResponse, '$.error')
        WHERE RunID = @RunID;

        IF @ChiCapNhat = 0
        BEGIN
        SELECT @RunID AS RunID, N'LoiSolver' AS TrangThai, CAST(0 AS BIT) AS KhaThi,
               NULL AS SoNhuCau, NULL AS SoSlotDaXep, NULL AS TietTrongLe, NULL AS SoGvKhongCoBuoiRanh,
               NULL AS SoLuotVuotTranTietNgay, NULL AS SoTietViPhamChaoCo, NULL AS SoLuotLechTrack, NULL AS SoTietShKhongKem,
               JSON_VALUE(@StatusResponse, '$.error') AS ThongBao;
        END
        RETURN;
    END

    -- @JobStatus = 'done' -> parse result lồng bên trong, lưu kết quả
    DECLARE @Result NVARCHAR(MAX) = JSON_QUERY(@StatusResponse, '$.result');
    DECLARE @KhaThi BIT = CASE WHEN JSON_VALUE(@Result, '$.khaThi') = 'true' THEN 1 ELSE 0 END;
    DECLARE @TrangThai NVARCHAR(50) = JSON_VALUE(@Result, '$.trangThai');

    UPDATE tblTKB_ChayAutoLog
    SET ThoiGianKetThuc = SYSUTCDATETIME(),
        TrangThai = @TrangThai,
        KhaThi = @KhaThi,
        LoiChiTiet = NULL,
        SoSlotDaXep = (SELECT COUNT(*) FROM OPENJSON(@Result, '$.slots')),
        TietTrongLe = TRY_CAST(JSON_VALUE(@Result, '$.viPham.tietTrongLe') AS INT),
        SoGvKhongCoBuoiRanh = TRY_CAST(JSON_VALUE(@Result, '$.viPham.soGvKhongCoBuoiRanh') AS INT),
        SoLuotVuotTranTietNgay = TRY_CAST(JSON_VALUE(@Result, '$.viPham.soLuotVuotTranTietNgay') AS INT),
        SoTietViPhamChaoCo = TRY_CAST(JSON_VALUE(@Result, '$.viPham.soTietViPhamChaoCo') AS INT),
        SoLuotLechTrack = TRY_CAST(JSON_VALUE(@Result, '$.viPham.soLuotLechTrack') AS INT),
        SoTietShKhongKem = TRY_CAST(JSON_VALUE(@Result, '$.viPham.soTietShKhongKem') AS INT)
    WHERE RunID = @RunID;

    IF @KhaThi = 1
    BEGIN
        ;WITH slotJson AS (
            SELECT * FROM OPENJSON(@Result, '$.slots')
            WITH (
                MaLop VARCHAR(10) '$.maLop',
                Thu INT '$.thu',
                Buoi VARCHAR(10) '$.buoi',
                Tiet INT '$.tiet',
                MaMon VARCHAR(10) '$.maMon',
                MaGV VARCHAR(10) '$.maGV'
            )
        ),
        phongJson AS (
            SELECT * FROM OPENJSON(@Result, '$.phongDaXep')
            WITH (
                MaLop VARCHAR(10) '$.maLop',
                Thu INT '$.thu',
                Buoi VARCHAR(10) '$.buoi',
                Tiet INT '$.tiet',
                MaPhong VARCHAR(10) '$.maPhong'
            )
        )
        -- Chong trung: khi chay Auto tuan tu nhieu lan tren cung 1 RunID (vd tung khoi), rang buoc
        -- GVBanCoDinh (doc tu tblTKB_LichHopCoDinh, ap dung TOAN TRUONG bat ke @Khoi) khien solver
        -- lap lai dung cac slot lich hop da khoa tay o moi lan goi — neu insert khong loc se bi nhan
        -- ban (tung thay 551 dong HOP thanh 7163 dong sau 12 lan chay tung khoi). NOT EXISTS chan dut.
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, s.MaLop, s.Thu, s.Buoi, s.Tiet, s.MaMon, s.MaGV, p.MaPhong
        FROM slotJson s
        LEFT JOIN phongJson p ON p.MaLop = s.MaLop AND p.Thu = s.Thu AND p.Buoi = s.Buoi AND p.Tiet = s.Tiet
        WHERE NOT EXISTS (
            SELECT 1 FROM tblTKB_KetQuaXep k
            WHERE k.RunID = @RunID AND k.MaLop = s.MaLop AND k.Thu = s.Thu AND k.Buoi = s.Buoi
              AND k.Tiet = s.Tiet AND k.MaMon = s.MaMon AND k.MaGV = s.MaGV
        );

        -- XoayTro (2026-09-12): CHI gan khi caller CHU DONG truyen @XoayTroMacDinh (vd Round 4 —
        -- "phan con lai" truyen 90) — mac dinh NULL de KHONG can thiep khi SP nay dang duoc goi tu
        -- ben trong vong lap Round 2 (spAPI_TkbXepDoKhanHiem tu poll rieng, roi tu gan dung diem khan
        -- hiem cua GV sau khi vong WHILE ket thuc — neu o day da gan truoc thi dieu kien "XoayTro IS
        -- NULL" ben do se khong con dong nao de cap nhat, giu nham muc mac dinh nay thay vi diem dung).
        IF @XoayTroMacDinh IS NOT NULL
            UPDATE tblTKB_KetQuaXep SET XoayTro = @XoayTroMacDinh WHERE RunID = @RunID AND XoayTro IS NULL;

        -- BUG (phat hien 2026-09-10): thieu DELETE truoc INSERT nen moi lan PhanConLai xu ly xong
        -- (DangChay -> Optimal) lai CONG DON them ban ghi khongXepDuoc cu, khong xoa ban ghi lan
        -- truoc — gay hien thi trung lap nhieu lan tren UI "Chua xep duoc" (vd 1 nhom bi lap x4 sau
        -- 4 lan goi PhanConLai lien tiep tren cung RunID). Xoa het ket qua CU cua dung RunID nay
        -- truoc khi ghi ket qua MOI, vi day la "trang thai hien tai" chu khong phai lich su.
        DELETE FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID;

        INSERT INTO tblTKB_ChayAutoKhongXepDuoc (RunID, MaLop, MaMon, MaGV, SoTiet)
        SELECT @RunID, MaLop, MaMon, MaGV, SoTiet
        FROM OPENJSON(@Result, '$.khongXepDuoc')
        WITH (
            MaLop VARCHAR(10) '$.maLop',
            MaMon VARCHAR(15) '$.maMon',
            MaGV VARCHAR(15) '$.maGV',
            SoTiet INT '$.soTiet'
        );

        -- Chen tiet "HOP" nhu 1 mon hoc thuc su vao TKB (giong quy uoc STKB) — hien thi truc quan
        -- tren luoi TKB thay vi chi la rang buoc ngam. MaLop dung tam MaNhom (vd 'TUNHIEN','KT','01')
        -- de biet la hop cua nhom nao. Chi chen cho GV THUC SU co mat trong lan chay nay (tranh chen
        -- thua GV khong lien quan khi chi chay 1/vai khoi).
        -- GV thinh giang (2026-09-11): dong bo voi spAPI_TkbChayAuto — loai khoi hop To chuyen mon.
        -- 2026-10-07: lich hop lay tu dbo.fnTkbLichHopGV theo dung tuan cua lan chay (tblTKB_ChayAutoLog.TuanHienTai)
        -- — dong bo 1 cho voi spAPI_TkbChayAuto (truoc day CTE GVNhom lap lai o day, tung bi lech nhau).
        -- Bo KhoiCap23SH (khoa tiet SH, khong phai cuoc hop that, khong chen dong HOP).
        DECLARE @TuanHop INT = (SELECT TOP 1 TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
        ;WITH HopExpanded AS (
            SELECT DISTINCT h.MaGV, h.MaNhom, h.Thu, h.Buoi, h.Tiet
            FROM dbo.fnTkbLichHopGV(@TuanHop) h
            WHERE h.LoaiNhom <> 'KhoiCap23SH' AND h.Tiet <= 5
        )
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, he.MaNhom, he.Thu, he.Buoi, he.Tiet, 'HOP', he.MaGV, NULL
        FROM HopExpanded he
        WHERE he.MaGV IN (SELECT DISTINCT MaGV FROM tblTKB_KetQuaXep WHERE RunID = @RunID)
          AND NOT EXISTS (
              SELECT 1 FROM tblTKB_KetQuaXep k
              WHERE k.RunID = @RunID AND k.MaLop = he.MaNhom AND k.Thu = he.Thu AND k.Buoi = he.Buoi
                AND k.Tiet = he.Tiet AND k.MaMon = 'HOP' AND k.MaGV = he.MaGV
          );

        -- Cum tach R23 (2026-09-10, theo yeu cau nguoi dung): chen marker "dang tach nhom" vao dung
        -- lich cua LOP NGUON tai moi slot ma CUM dang active (bat ky NhomCon nao co tiet that trong
        -- RunID nay) — CHI de hien thi/theo doi (lop goc phai thay du ca lop phan ban va AV vi chung
        -- lay chung 1 nguon hoc sinh), KHONG anh huong rang buoc solver (R23 da xu ly rieng trong C#).
        -- MaMon = dung MaCumTach (da dang ky ten hien thi trong tblTKB_MonHoc, vd "Tach nhom (11AV1,
        -- 11AV2, ...)"). NOT EXISTS chan khong de/lai neu lop nguon da co tiet that o do (khong nen
        -- xay ra vi R23 da cam, nhung phong ngua an toan giong het pattern HOP o tren).
        ;WITH CumActive AS (
            SELECT DISTINCT ct.MaCumTach, ln.MaLop AS LopNguon, k.Thu, k.Buoi, k.Tiet
            FROM tblTKB_CumTach ct
            INNER JOIN tblTKB_CumTach_NhomCon nc ON nc.CumTachID = ct.ID
            INNER JOIN tblTKB_CumTach_LopNguon ln ON ln.CumTachID = ct.ID
            INNER JOIN tblTKB_KetQuaXep k ON k.MaLop = nc.MaLop AND k.RunID = @RunID
            WHERE ct.Enable = 1
        )
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, ca.LopNguon, ca.Thu, ca.Buoi, ca.Tiet, ca.MaCumTach, ca.MaCumTach, NULL
        FROM CumActive ca
        WHERE NOT EXISTS (
            SELECT 1 FROM tblTKB_KetQuaXep k
            WHERE k.RunID = @RunID AND k.MaLop = ca.LopNguon AND k.Thu = ca.Thu AND k.Buoi = ca.Buoi AND k.Tiet = ca.Tiet
        );
    END

    IF @ChiCapNhat = 0
    BEGIN
        SELECT RunID, TrangThai, KhaThi, SoNhuCau, SoSlotDaXep, TietTrongLe, SoGvKhongCoBuoiRanh,
               SoLuotVuotTranTietNgay, SoTietViPhamChaoCo, SoLuotLechTrack, SoTietShKhongKem,
               (SELECT COUNT(*) FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = l.RunID) AS SoNhomKhongXepDuoc,
               CAST(NULL AS NVARCHAR(500)) AS ThongBao
        FROM tblTKB_ChayAutoLog l WHERE RunID = @RunID;
    END
END