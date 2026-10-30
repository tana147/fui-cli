CREATE PROCEDURE spAPI_TkbSapTayThucHien
    @RunID INT,
    @Ops NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    -- 2026-10-06: thuc hien 1 "nuoc di" sap tay (tab Toan truong) — moi thao tac deu qua day de co the HOAN TAC
    -- (trinh duyet giu nuoc di nguoc). @Ops JSON:
    --   {"moves":[{"ID":1,"Thu":3,"Buoi":"Sang","Tiet":2},...],   -- chuyen vi tri (cung luc, nen hoan doi/day chuoi deu duoc)
    --    "gv":[{"ID":1,"MaGV":"NV..."}],                         -- doi giao vien cua tiet
    --    "del":[5,6],                                            -- go tiet (quay ve danh sach con thieu)
    --    "add":{"MaLop":"08C","MaMon":"VAN","MaGV":"NV..","Thu":3,"Buoi":"Sang","Tiet":2,"MaPhong":null},  -- them 1 tiet
    --    "adds":[{...},{...}],                                     -- them nhieu tiet (luu ca chuoi nhap); NewIDs = '1,2' theo thu tu
    --    "choPhepHop":[{"MaGV":"NV..","Thu":6,"Buoi":"Sang","Tiet":3}]}  -- chap nhan GV vang hop o gio do (pha luat co chu dich)
    -- Tat ca trong 1 giao dich; sau khi ghi kiem tra lai TRUNG LOP / TRUNG GV (ke ca hop) / TRUNG PHONG cua cac tiet bi
    -- dong cham — co trung thi huy toan bo. Luat mem (bao ban, so tiet/ngay, tiet doi...) KHONG chan: trang da canh bao
    -- truoc va nguoi sap chu dong chon. Tiet bi dong cham duoc KHOA TAY de lan chay Auto sau khong xoa.
    IF ISJSON(@Ops) <> 1
    BEGIN
        SELECT CAST(0 AS BIT) AS Success, N'Dữ liệu thao tác không hợp lệ' AS Message, CAST(NULL AS INT) AS NewID, N'' AS NewIDs;
        RETURN;
    END

    DECLARE @T TABLE (ID INT PRIMARY KEY);
    DECLARE @NewID INT = NULL;

    BEGIN TRAN;

    -- Go tiet
    INSERT INTO tblTKB_ChayAutoKhongXepDuoc (RunID, MaLop, MaMon, MaGV, SoTiet)
    SELECT k.RunID, k.MaLop, k.MaMon, k.MaGV, 1
    FROM tblTKB_KetQuaXep k
    WHERE k.RunID = @RunID AND k.ID IN (SELECT CAST(value AS INT) FROM OPENJSON(@Ops, '$.del'));
    DELETE kh FROM tblTKB_KetQuaXep_Khoa kh
    WHERE kh.KetQuaXepID IN (SELECT k.ID FROM tblTKB_KetQuaXep k WHERE k.RunID = @RunID
                             AND k.ID IN (SELECT CAST(value AS INT) FROM OPENJSON(@Ops, '$.del')));
    DELETE FROM tblTKB_KetQuaXep
    WHERE RunID = @RunID AND ID IN (SELECT CAST(value AS INT) FROM OPENJSON(@Ops, '$.del'));

    -- Chuyen vi tri
    UPDATE k SET Thu = m.Thu, Buoi = m.Buoi, Tiet = m.Tiet
    OUTPUT inserted.ID INTO @T (ID)
    FROM tblTKB_KetQuaXep k
    INNER JOIN OPENJSON(@Ops, '$.moves') WITH (ID INT, Thu INT, Buoi VARCHAR(10), Tiet INT) m ON m.ID = k.ID
    WHERE k.RunID = @RunID;

    -- Doi GV
    UPDATE k SET MaGV = g.MaGV
    FROM tblTKB_KetQuaXep k
    INNER JOIN OPENJSON(@Ops, '$.gv') WITH (ID INT, MaGV VARCHAR(15)) g ON g.ID = k.ID
    WHERE k.RunID = @RunID;
    INSERT INTO @T (ID)
    SELECT g.ID FROM OPENJSON(@Ops, '$.gv') WITH (ID INT) g
    WHERE NOT EXISTS (SELECT 1 FROM @T t WHERE t.ID = g.ID)
      AND EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k WHERE k.ID = g.ID AND k.RunID = @RunID);

    -- Them nhieu tiet (luu ca chuoi "nhap lien hoan"): them TUNG dong theo thu tu mang de NewIDs dung thu tu.
    DECLARE @NewIDs NVARCHAR(MAX) = N'', @i INT = 0, @n INT = 0, @one NVARCHAR(MAX);
    IF JSON_QUERY(@Ops, '$.adds') IS NOT NULL
    BEGIN
        SELECT @n = COUNT(*) FROM OPENJSON(@Ops, '$.adds');
        WHILE @i < @n
        BEGIN
            SET @one = JSON_QUERY(@Ops, '$.adds[' + CAST(@i AS NVARCHAR(10)) + ']');
            INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
            SELECT @RunID, a.MaLop, a.Thu, a.Buoi, a.Tiet, a.MaMon, a.MaGV, NULLIF(a.MaPhong, '')
            FROM OPENJSON(@one) WITH (MaLop VARCHAR(10), MaMon VARCHAR(20), MaGV VARCHAR(15), Thu INT,
                                     Buoi VARCHAR(10), Tiet INT, MaPhong VARCHAR(10)) a;
            SET @NewID = SCOPE_IDENTITY();
            INSERT INTO @T (ID) VALUES (@NewID);
            SET @NewIDs = @NewIDs + CASE WHEN @NewIDs = N'' THEN N'' ELSE N',' END + CAST(@NewID AS NVARCHAR(12));
            UPDATE x SET SoTiet = x.SoTiet - 1
            FROM tblTKB_ChayAutoKhongXepDuoc x
            INNER JOIN tblTKB_KetQuaXep k ON k.ID = @NewID AND x.RunID = @RunID AND x.MaLop = k.MaLop AND x.MaMon = k.MaMon
            WHERE x.SoTiet > 0;
            SET @i = @i + 1;
        END
        DELETE FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID AND SoTiet <= 0;
    END

    -- Them 1 tiet
    IF JSON_QUERY(@Ops, '$.add') IS NOT NULL
    BEGIN
        INSERT INTO tblTKB_KetQuaXep (RunID, MaLop, Thu, Buoi, Tiet, MaMon, MaGV, MaPhong)
        SELECT @RunID, a.MaLop, a.Thu, a.Buoi, a.Tiet, a.MaMon, a.MaGV, NULLIF(a.MaPhong, '')
        FROM OPENJSON(@Ops, '$.add') WITH (MaLop VARCHAR(10), MaMon VARCHAR(20), MaGV VARCHAR(15), Thu INT,
                                          Buoi VARCHAR(10), Tiet INT, MaPhong VARCHAR(10)) a;
        SET @NewID = SCOPE_IDENTITY();
        INSERT INTO @T (ID) VALUES (@NewID);
        SET @NewIDs = @NewIDs + CASE WHEN @NewIDs = N'' THEN N'' ELSE N',' END + CAST(@NewID AS NVARCHAR(12));
        UPDATE x SET SoTiet = x.SoTiet - 1
        FROM tblTKB_ChayAutoKhongXepDuoc x
        INNER JOIN tblTKB_KetQuaXep k ON k.ID = @NewID AND x.RunID = @RunID AND x.MaLop = k.MaLop AND x.MaMon = k.MaMon
        WHERE x.SoTiet > 0;
        DELETE FROM tblTKB_ChayAutoKhongXepDuoc WHERE RunID = @RunID AND SoTiet <= 0;
    END

    -- Kiem tra trung cung cho cac tiet bi dong cham
    DECLARE @Loi NVARCHAR(400) = NULL;
    SELECT TOP 1 @Loi = N'Lớp ' + a.MaLop + N' đã có ' + b.MaMon + N' ở Thứ ' + CAST(a.Thu AS NVARCHAR(2))
                 + CASE a.Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END + N' tiết ' + CAST(a.Tiet AS NVARCHAR(2))
    FROM @T t
    INNER JOIN tblTKB_KetQuaXep a ON a.ID = t.ID
    INNER JOIN tblTKB_KetQuaXep b ON b.RunID = a.RunID AND b.MaLop = a.MaLop AND b.Thu = a.Thu AND b.Buoi = a.Buoi
                                  AND b.Tiet = a.Tiet AND b.ID <> a.ID AND b.MaMon <> 'HOP' AND a.MaMon <> 'HOP';
    IF @Loi IS NULL
        SELECT TOP 1 @Loi = N'Giáo viên ' + ISNULL(g.HoTen, a.MaGV) + N' đang ' + CASE WHEN b.MaMon = 'HOP' THEN N'họp' ELSE N'dạy lớp ' + b.MaLop END
                     + N' ở Thứ ' + CAST(a.Thu AS NVARCHAR(2)) + CASE a.Buoi WHEN 'Sang' THEN N' sáng' ELSE N' chiều' END
                     + N' tiết ' + CAST(a.Tiet AS NVARCHAR(2))
        FROM @T t
        INNER JOIN tblTKB_KetQuaXep a ON a.ID = t.ID
        INNER JOIN tblTKB_KetQuaXep b ON b.RunID = a.RunID AND b.MaGV = a.MaGV AND b.Thu = a.Thu AND b.Buoi = a.Buoi
                                      AND b.Tiet = a.Tiet AND b.ID <> a.ID
        LEFT JOIN tblTKB_GiaoVien g ON g.MaGV = a.MaGV
        WHERE a.MaGV IS NOT NULL AND a.MaGV <> a.MaMon
          -- Nguoi sap da chu dong chap nhan "GV vang hop" o gio nay (phuong an pha luat da chon tren trang).
          AND NOT (b.MaMon = 'HOP' AND EXISTS (
                SELECT 1 FROM OPENJSON(@Ops, '$.choPhepHop') WITH (MaGV VARCHAR(15), Thu INT, Buoi VARCHAR(10), Tiet INT) h
                WHERE h.MaGV = a.MaGV AND h.Thu = a.Thu AND h.Buoi = a.Buoi AND h.Tiet = a.Tiet));
    IF @Loi IS NULL
        SELECT TOP 1 @Loi = N'Phòng ' + a.MaPhong + N' đang được lớp ' + b.MaLop + N' dùng cùng giờ'
        FROM @T t
        INNER JOIN tblTKB_KetQuaXep a ON a.ID = t.ID
        INNER JOIN tblTKB_KetQuaXep b ON b.RunID = a.RunID AND b.MaPhong = a.MaPhong AND b.Thu = a.Thu AND b.Buoi = a.Buoi
                                      AND b.Tiet = a.Tiet AND b.ID <> a.ID
        WHERE a.MaPhong IS NOT NULL;
    IF @Loi IS NOT NULL
    BEGIN
        ROLLBACK;
        SELECT CAST(0 AS BIT) AS Success, @Loi + N' — chưa thay đổi gì' AS Message, CAST(NULL AS INT) AS NewID, N'' AS NewIDs;
        RETURN;
    END

    INSERT INTO tblTKB_KetQuaXep_Khoa (KetQuaXepID, KhoaUser, KhoaTime)
    SELECT t.ID, @sys_UserID, GETDATE() FROM @T t
    WHERE NOT EXISTS (SELECT 1 FROM tblTKB_KetQuaXep_Khoa kh WHERE kh.KetQuaXepID = t.ID);

    COMMIT;
    SELECT CAST(1 AS BIT) AS Success, N'Đã lưu' AS Message, @NewID AS NewID, @NewIDs AS NewIDs;
END
