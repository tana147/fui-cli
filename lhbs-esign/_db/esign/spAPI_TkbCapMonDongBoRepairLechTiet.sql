CREATE PROCEDURE spAPI_TkbCapMonDongBoRepairLechTiet
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-12 (theo de xuat nguoi dung: "giai thuat tong quat de sua code la chay chu khong phai
    -- chi xu ly theo memory"). Cong nghiep hoa quy tac da ghi trong memory tkb-solver-cumtach-thpt.md
    -- muc "Quy tac dat tiet khi 2 mon ghep cap (R24) LECH so tiet/tuan": khi 1 cap (LopA,MonA) va
    -- (LopB,MonB) trong tblTKB_CapMonDongBoGio co SO TIET/TUAN KHAC NHAU, ca cap phai nam trong 1
    -- khoi LIEN TIEP cung buoi cung ngay dung bang so tiet cua ben NHIEU hon — ben IT tiet hon chiem
    -- dung so tiet DAU cua khoi do.
    --
    -- R24 trong TkbCpSatSolver.cs CHI ep "2 ben cung ban/ranh dong thoi" (sumA==sumB moi slot) — KHONG
    -- tu quyet dinh vi tri lien tiep/dau khoi, nen CP-SAT (hoac nguoi sua tay) co the rai tiet du cua
    -- ben nhieu hon ra bat ky dau trong tuan, dung ve mat rang buoc nhung sai quy uoc thuc te truong.
    -- SP nay: DO tung cap chua dung mau, TU TIM 1 khoi lien tiep moi con trong that (kiem tra ca GV
    -- lan Lop/LopNguon cua cum tach neu co) va TU DOI vao — chi bao cao (khong ep) neu khong tim duoc.

    DECLARE @KetQua TABLE (CapID INT, MaLopA VARCHAR(10), MaMonA VARCHAR(15), MaLopB VARCHAR(10), MaMonB VARCHAR(15),
                           KetQua NVARCHAR(30), ChiTiet NVARCHAR(200));

    DECLARE cap_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT ID, MaLopA, MaMonA, MaLopB, MaMonB FROM tblTKB_CapMonDongBoGio WHERE Enable = 1;

    DECLARE @CapID INT, @MaLopA VARCHAR(10), @MaMonA VARCHAR(15), @MaLopB VARCHAR(10), @MaMonB VARCHAR(15);
    OPEN cap_cursor;
    FETCH NEXT FROM cap_cursor INTO @CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @nA INT, @nB INT, @GvA VARCHAR(9), @GvB VARCHAR(9);
        SELECT @nA = COUNT(*), @GvA = MAX(MaGV) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLopA AND MaMon = @MaMonA;
        SELECT @nB = COUNT(*), @GvB = MAX(MaGV) FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLopB AND MaMon = @MaMonB;

        IF @nA = 0 OR @nB = 0
        BEGIN
            INSERT INTO @KetQua VALUES (@CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB, N'BoQua', N'1 ben chua duoc xep tiet nao, chua co gi de sua');
            GOTO NextCap;
        END

        IF @nA = @nB
        BEGIN
            INSERT INTO @KetQua VALUES (@CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB, N'BoQua', N'So tiet bang nhau, khong thuoc pham vi SP nay (dung spAPI_TkbCapMonDongBoKiemTra de check dong bo slot)');
            GOTO NextCap;
        END

        DECLARE @LopNhieu VARCHAR(10), @MonNhieu VARCHAR(15), @GvNhieu VARCHAR(9), @SoNhieu INT;
        DECLARE @LopIt VARCHAR(10), @MonIt VARCHAR(15), @GvIt VARCHAR(9), @SoIt INT;
        IF @nA > @nB
        BEGIN
            SET @LopNhieu = @MaLopA; SET @MonNhieu = @MaMonA; SET @GvNhieu = @GvA; SET @SoNhieu = @nA;
            SET @LopIt = @MaLopB; SET @MonIt = @MaMonB; SET @GvIt = @GvB; SET @SoIt = @nB;
        END
        ELSE
        BEGIN
            SET @LopNhieu = @MaLopB; SET @MonNhieu = @MaMonB; SET @GvNhieu = @GvB; SET @SoNhieu = @nB;
            SET @LopIt = @MaLopA; SET @MonIt = @MaMonA; SET @GvIt = @GvA; SET @SoIt = @nA;
        END

        -- Kiem tra xem hien tai da dung mau chua: ben Nhieu phai nam LIEN TIEP 1 (Thu,Buoi), ben It
        -- phai la dung SoIt tiet DAU cua chinh khoi lien tiep do (cung Thu/Buoi, Tiet nho nhat).
        DECLARE @DaDungMau BIT = 0;
        ;WITH NhieuSlots AS (
            SELECT Thu, Buoi, Tiet, ROW_NUMBER() OVER (ORDER BY Tiet) AS rn
            FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopNhieu AND MaMon = @MonNhieu
        )
        SELECT @DaDungMau = CASE WHEN
            (SELECT COUNT(DISTINCT Thu) FROM NhieuSlots) = 1
            AND (SELECT COUNT(DISTINCT Buoi) FROM NhieuSlots) = 1
            AND NOT EXISTS (SELECT 1 FROM NhieuSlots n1 WHERE NOT EXISTS (
                SELECT 1 FROM NhieuSlots n0 WHERE n0.rn = 1 AND n1.Tiet = n0.Tiet + n1.rn - 1))
            AND EXISTS (
                SELECT 1 FROM NhieuSlots n0 WHERE n0.rn = 1
                AND (SELECT COUNT(*) FROM tblTKB_KetQuaXep it
                     WHERE it.RunID = @RunID AND it.MaLop = @LopIt AND it.MaMon = @MonIt
                       AND it.Thu = n0.Thu AND it.Buoi = n0.Buoi AND it.Tiet >= n0.Tiet AND it.Tiet < n0.Tiet + @SoIt) = @SoIt
                AND NOT EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep it2
                    WHERE it2.RunID = @RunID AND it2.MaLop = @LopIt AND it2.MaMon = @MonIt
                      AND NOT (it2.Thu = n0.Thu AND it2.Buoi = n0.Buoi AND it2.Tiet >= n0.Tiet AND it2.Tiet < n0.Tiet + @SoIt)
                )
            )
        THEN 1 ELSE 0 END;

        IF @DaDungMau = 1
        BEGIN
            INSERT INTO @KetQua VALUES (@CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB, N'DaDung', N'Da dung mau (lien tiep, ben it tiet o dau khoi) — khong can sua');
            GOTO NextCap;
        END

        -- Chua dung mau: tim 1 khoi @SoNhieu tiet lien tiep moi, kiem tra ranh cho CA GV lan Lop
        -- (bao gom LopNguon neu Lop dang la NhomCon cua 1 cum tach — tranh dam vao gio cum dang active).
        DECLARE @TimThay BIT = 0, @ThuMoi INT, @BuoiMoi VARCHAR(10), @TietBatDauMoi INT;
        DECLARE day_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT d.Thu, d.Buoi, tb.TietBatDau FROM (VALUES
                (2,N'Sang',5),(3,N'Sang',5),(4,N'Sang',5),(5,N'Sang',5),(6,N'Sang',5),
                (2,N'Chieu',4),(3,N'Chieu',4),(4,N'Chieu',4),(5,N'Chieu',4),(6,N'Chieu',4)
            ) d(Thu,Buoi,SoTietToiDa)
            CROSS APPLY (SELECT TietBatDau FROM (VALUES(1),(2),(3),(4),(5)) t(TietBatDau) WHERE TietBatDau + @SoNhieu - 1 <= d.SoTietToiDa) tb;

        DECLARE @Thu INT, @Buoi VARCHAR(10), @TietBatDau INT;
        OPEN day_cursor;
        FETCH NEXT FROM day_cursor INTO @Thu, @Buoi, @TietBatDau;
        WHILE @@FETCH_STATUS = 0 AND @TimThay = 0
        BEGIN
            DECLARE @OK BIT = 1;
            -- GV Nhieu phai ranh tai TOAN BO @SoNhieu tiet (tru chinh cac dong hien tai cua no, vi se bi doi di).
            -- 2026-09-12: bo quet cross-RunID (Enable=1) — kien truc moi (spAPI_TkbXepDoKhanHiem) hop
            -- nhat CA TRUONG ve 1 RunID duy nhat moi tuan, nen chi can xet trong dung @RunID nay la du
            -- va chinh xac hon (tranh nham voi RunID cu/tham khao con Enable=1 tu tuan/dot khac).
            IF EXISTS (
                SELECT 1 FROM (SELECT @TietBatDau + n AS Tiet FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoNhieu) tiets
                WHERE EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep k
                    WHERE k.RunID = @RunID AND k.MaGV = @GvNhieu AND k.Thu = @Thu AND k.Buoi = @Buoi AND k.Tiet = tiets.Tiet
                      AND NOT (k.MaLop = @LopNhieu AND k.MaMon = @MonNhieu)
                )
            ) SET @OK = 0;
            -- GV It phai ranh tai @SoIt tiet DAU (tru chinh cac dong hien tai cua no)
            IF @OK = 1 AND EXISTS (
                SELECT 1 FROM (SELECT @TietBatDau + n AS Tiet FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoIt) tiets
                WHERE EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep k
                    WHERE k.RunID = @RunID AND k.MaGV = @GvIt AND k.Thu = @Thu AND k.Buoi = @Buoi AND k.Tiet = tiets.Tiet
                      AND NOT (k.MaLop = @LopIt AND k.MaMon = @MonIt)
                )
            ) SET @OK = 0;
            -- Lop Nhieu (hoac LopNguon cua no neu la NhomCon 1 cum) phai ranh tai toan bo @SoNhieu tiet
            IF @OK = 1 AND EXISTS (
                SELECT 1 FROM (SELECT @TietBatDau + n AS Tiet FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoNhieu) tiets
                WHERE EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep k
                    WHERE k.RunID = @RunID AND k.MaLop = @LopNhieu AND k.Thu = @Thu AND k.Buoi = @Buoi AND k.Tiet = tiets.Tiet
                      AND NOT (k.MaMon = @MonNhieu)
                )
            ) SET @OK = 0;
            -- Lop It phai ranh tai @SoIt tiet dau
            IF @OK = 1 AND EXISTS (
                SELECT 1 FROM (SELECT @TietBatDau + n AS Tiet FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoIt) tiets
                WHERE EXISTS (
                    SELECT 1 FROM tblTKB_KetQuaXep k
                    WHERE k.RunID = @RunID AND k.MaLop = @LopIt AND k.Thu = @Thu AND k.Buoi = @Buoi AND k.Tiet = tiets.Tiet
                      AND NOT (k.MaMon = @MonIt)
                )
            ) SET @OK = 0;

            IF @OK = 1
            BEGIN
                SET @TimThay = 1; SET @ThuMoi = @Thu; SET @BuoiMoi = @Buoi; SET @TietBatDauMoi = @TietBatDau;
            END
            FETCH NEXT FROM day_cursor INTO @Thu, @Buoi, @TietBatDau;
        END
        CLOSE day_cursor; DEALLOCATE day_cursor;

        IF @TimThay = 0
        BEGIN
            INSERT INTO @KetQua VALUES (@CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB, N'KhongTimDuoc',
                N'Khong tim duoc khoi ' + CAST(@SoNhieu AS NVARCHAR(5)) + N' tiet lien tiep nao con trong cho ca 2 GV/Lop — can xu ly tay/cascade sau');
            GOTO NextCap;
        END

        -- Thuc hien doi: xoa cac dong cu (giu lai Khoa neu co, khoa lai o vi tri moi), chen vao khoi moi.
        DECLARE @LockedNhieu BIT = (SELECT CASE WHEN EXISTS (
            SELECT 1 FROM tblTKB_KetQuaXep k INNER JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
            WHERE k.RunID = @RunID AND k.MaLop = @LopNhieu AND k.MaMon = @MonNhieu) THEN 1 ELSE 0 END);
        DECLARE @LockedIt BIT = (SELECT CASE WHEN EXISTS (
            SELECT 1 FROM tblTKB_KetQuaXep k INNER JOIN tblTKB_KetQuaXep_Khoa kh ON kh.KetQuaXepID = k.ID
            WHERE k.RunID = @RunID AND k.MaLop = @LopIt AND k.MaMon = @MonIt) THEN 1 ELSE 0 END);

        DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (
            SELECT ID FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopNhieu AND MaMon = @MonNhieu);
        DELETE FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopNhieu AND MaMon = @MonNhieu;
        DELETE FROM tblTKB_KetQuaXep_Khoa WHERE KetQuaXepID IN (
            SELECT ID FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopIt AND MaMon = @MonIt);
        DELETE FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopIt AND MaMon = @MonIt;

        ;WITH Seq AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoNhieu)
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, @LopNhieu, @ThuMoi, @BuoiMoi, @TietBatDauMoi + n, @MonNhieu, @GvNhieu, NULL FROM Seq;

        ;WITH Seq AS (SELECT n FROM (VALUES(0),(1),(2),(3),(4)) v(n) WHERE n < @SoIt)
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, @LopIt, @ThuMoi, @BuoiMoi, @TietBatDauMoi + n, @MonIt, @GvIt, NULL FROM Seq;

        IF @LockedNhieu = 1
            INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
            SELECT ID FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopNhieu AND MaMon = @MonNhieu;
        IF @LockedIt = 1
            INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID)
            SELECT ID FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @LopIt AND MaMon = @MonIt;

        INSERT INTO @KetQua VALUES (@CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB, N'DaSua',
            N'Doi ve Thu' + CAST(@ThuMoi AS NVARCHAR(5)) + N'-' + @BuoiMoi + N'-tiet' + CAST(@TietBatDauMoi AS NVARCHAR(5))
            + N' (' + @LopNhieu + N'-' + @MonNhieu + N' x' + CAST(@SoNhieu AS NVARCHAR(5))
            + N', ' + @LopIt + N'-' + @MonIt + N' x' + CAST(@SoIt AS NVARCHAR(5)) + N' o dau khoi)');

        NextCap:
        FETCH NEXT FROM cap_cursor INTO @CapID, @MaLopA, @MaMonA, @MaLopB, @MaMonB;
    END
    CLOSE cap_cursor; DEALLOCATE cap_cursor;

    SELECT * FROM @KetQua ORDER BY CapID;
END
