CREATE PROCEDURE spAPI_TkbGoiYChuoi
    @RunID INT,
    @MaLop VARCHAR(10),
    @MaMon VARCHAR(10),
    @MaGV VARCHAR(10),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Goi y TU TINH (khong qua AI — nhanh, luon san sang, khong phu thuoc mang ngoai, 2026-08-30
    -- theo yeu cau nguoi dung sau khi thay Gemini phan hoi cham). Tim cho de xep them 1 tiet mon
    -- @MaMon cua GV @MaGV vao lop @MaLop:
    --   Buoc 1 (TRUC_TIEP): tim khung gio ma CA Lop LAN GV cung dang RANH -> xep thang, khong can doi gi.
    --   Buoc 2 (CHUOI_1_BUOC, chi chay neu Buoc 1 khong co ket qua nao): tim khung gio Lop RANH nhung
    --     GV dang BAN (day 1 lop khac o do — "Occupant") — kiem tra Occupant co the DOI sang 1 khung
    --     gio KHAC ma CA lop cua no LAN GV (chinh @MaGV) deu ranh khong. Neu co, day la 1 chuoi domino
    --     hop le: (1) doi Occupant sang cho moi, (2) xep don vi dang thieu vao cho vua trong ra.
    -- Tra ve toi da 5 dong ket qua, moi dong la 1 phuong an doc lap (khong lien quan nhau).

    -- Suc chua THAT theo khoi (dung logic voi C# solver): Tieu hoc/THCS (01-09) = 4 tiet sang, THPT
    -- (10-12) = 5 tiet sang; chieu luon 4 tiet moi cap. Tranh goi y ra khung gio khong ton tai (vd
    -- Chieu-tiet5, hoac Sang-tiet5 cho THCS).
    DECLARE @KhoiLop VARCHAR(2) = LEFT(@MaLop, 2);
    DECLARE @SangMax INT = CASE WHEN @KhoiLop IN ('10','11','12') THEN 5 ELSE 4 END;

    ;WITH AllSlots AS (
        SELECT d.Thu, b.Buoi, t.Tiet
        FROM (SELECT 2 AS Thu UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) d
        CROSS JOIN (SELECT N'Sang' AS Buoi UNION SELECT N'Chieu') b
        CROSS JOIN (SELECT 1 AS Tiet UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t
        WHERE (b.Buoi = N'Chieu' AND t.Tiet <= 4) OR (b.Buoi = N'Sang' AND t.Tiet <= @SangMax)
    ),
    LopBusy AS (
        SELECT Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop
    ),
    LopFree AS (
        SELECT s.* FROM AllSlots s
        WHERE NOT EXISTS (SELECT 1 FROM LopBusy b WHERE b.Thu = s.Thu AND b.Buoi = s.Buoi AND b.Tiet = s.Tiet)
    ),
    GVRow AS (
        SELECT ID, Thu, Buoi, Tiet, MaLop AS OccupantLop, MaMon AS OccupantMon
        FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV
    ),
    TrucTiep AS (
        SELECT lf.Thu, lf.Buoi, lf.Tiet
        FROM LopFree lf
        WHERE NOT EXISTS (SELECT 1 FROM GVRow g WHERE g.Thu = lf.Thu AND g.Buoi = lf.Buoi AND g.Tiet = lf.Tiet)
    )
    SELECT TOP 5
        N'TRUC_TIEP' AS LoaiGoiY,
        Thu, Buoi, Tiet,
        CAST(NULL AS VARCHAR(10)) AS OccupantLop, CAST(NULL AS VARCHAR(10)) AS OccupantMon,
        CAST(NULL AS INT) AS Thu2, CAST(NULL AS NVARCHAR(10)) AS Buoi2, CAST(NULL AS INT) AS Tiet2
    FROM TrucTiep;

    IF @@ROWCOUNT = 0
    BEGIN
        ;WITH AllSlots AS (
            SELECT d.Thu, b.Buoi, t.Tiet
            FROM (SELECT 2 AS Thu UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6) d
            CROSS JOIN (SELECT N'Sang' AS Buoi UNION SELECT N'Chieu') b
            CROSS JOIN (SELECT 1 AS Tiet UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) t
            WHERE (b.Buoi = N'Chieu' AND t.Tiet <= 4) OR (b.Buoi = N'Sang' AND t.Tiet <= @SangMax)
        ),
        LopBusy AS (
            SELECT Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaLop = @MaLop
        ),
        LopFree AS (
            SELECT s.* FROM AllSlots s
            WHERE NOT EXISTS (SELECT 1 FROM LopBusy b WHERE b.Thu = s.Thu AND b.Buoi = s.Buoi AND b.Tiet = s.Tiet)
        ),
        GVRow AS (
            SELECT ID, Thu, Buoi, Tiet, MaLop AS OccupantLop, MaMon AS OccupantMon
            FROM tblTKB_KetQuaXep WHERE RunID = @RunID AND MaGV = @MaGV
        ),
        Blocked AS (
            SELECT lf.Thu, lf.Buoi, lf.Tiet, g.OccupantLop, g.OccupantMon
            FROM LopFree lf
            INNER JOIN GVRow g ON g.Thu = lf.Thu AND g.Buoi = lf.Buoi AND g.Tiet = lf.Tiet
        ),
        AllBusy AS (
            SELECT MaLop, Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID
        )
        SELECT TOP 5
            N'CHUOI_1_BUOC' AS LoaiGoiY,
            b.Thu, b.Buoi, b.Tiet, b.OccupantLop, b.OccupantMon,
            s2.Thu AS Thu2, s2.Buoi AS Buoi2, s2.Tiet AS Tiet2
        FROM Blocked b
        CROSS APPLY (
            SELECT TOP 1 s2.Thu, s2.Buoi, s2.Tiet
            FROM AllSlots s2
            WHERE NOT (s2.Thu = b.Thu AND s2.Buoi = b.Buoi AND s2.Tiet = b.Tiet)
              AND NOT EXISTS (SELECT 1 FROM AllBusy o WHERE o.MaLop = b.OccupantLop AND o.Thu = s2.Thu AND o.Buoi = s2.Buoi AND o.Tiet = s2.Tiet)
              AND NOT EXISTS (SELECT 1 FROM GVRow g2 WHERE g2.Thu = s2.Thu AND g2.Buoi = s2.Buoi AND g2.Tiet = s2.Tiet)
        ) s2;
    END
END
