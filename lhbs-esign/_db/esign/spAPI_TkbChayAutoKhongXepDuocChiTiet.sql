CREATE PROCEDURE spAPI_TkbChayAutoKhongXepDuocChiTiet
    @RunID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- 2026-09-15 (theo de xuat nguoi dung "tu van giai phap toan + CNTT" sau khi tu tay dieu tra
    -- JA/01A — phat hien lop 39/40 slot da day, 1 slot trong con lai dung luc GVCN vuong hop co dinh
    -- khoi 1): tu dong hoa dung viec chan doan thu cong do cho MOI dong trong
    -- tblTKB_ChayAutoKhongXepDuoc — thay vi Claude phai doi chieu tay tung truong hop, SP nay tra ve
    -- NGUYEN NHAN da phan loai + so lieu cu the, dung 1 luoi (Thu,Buoi,Tiet) chuan hoa theo dung cap
    -- hoc (Tieu hoc/THCS = 4 tiet/buoi, THPT = 5 sang/4 chieu — khop SoTietThatCuaBuoi() trong
    -- TkbCpSatSolver.cs, TONG TUAN quy doi giong nhau moi ngay nen khong can tach rieng ngay CLB).
    --
    -- Phan loai NguyenNhan (uu tien theo thu tu kiem tra):
    --   LopHetCho        : lop KHONG CON slot trong nao (0 slot chua co tiet nao) — het cho vat ly.
    --   GVHetCho         : GV KHONG CON slot ranh nao (da day/bi cam tuyet doi kin tuan).
    --   TrungLichCoDinh  : ca lop VA GV deu con slot rieng, nhung GIAO NHAU = 0 — dung nhung slot
    --                       lop con trong thi GV lai dang ban viec khac (day lop khac/hop) — xem cot
    --                       ChiTietTrungLich de biet CU THE GV dang lam gi o tung slot lop con trong.
    --   KhongRoNguyenNhan: giao nhau > 0 (co it nhat 1 slot ca 2 cung ranh) MA VAN ket — dau hieu co
    --                       rang buoc KHAC dang chan (R7/pattern mon/CumTach/CapMonDongBo...), can dieu
    --                       tra sau rieng, KHONG PHAI don gian het cho.
    ;WITH SlotGrid AS (
        SELECT Thu, Buoi FROM (VALUES (2,N'Sang'),(2,N'Chieu'),(3,N'Sang'),(3,N'Chieu'),(4,N'Sang'),(4,N'Chieu'),(5,N'Sang'),(5,N'Chieu'),(6,N'Sang'),(6,N'Chieu')) b(Thu,Buoi)
    ),
    Nums AS (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5),
    KXD AS (
        SELECT k.ID, k.MaLop, k.MaMon, k.MaGV, k.SoTiet, LEFT(k.MaLop, 2) AS Khoi
        FROM tblTKB_ChayAutoKhongXepDuoc k
        WHERE k.RunID = @RunID
    ),
    Grid AS (
        SELECT kxd.ID, sg.Thu, sg.Buoi, n.n AS Tiet
        FROM KXD kxd
        CROSS JOIN SlotGrid sg
        CROSS JOIN Nums n
        WHERE n.n <= CASE
            WHEN kxd.Khoi IN ('10', '11', '12') THEN CASE WHEN sg.Buoi = N'Sang' THEN 5 ELSE 4 END
            ELSE 4
        END
    ),
    LopBusy AS (SELECT DISTINCT MaLop, Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID),
    GVBusy AS (SELECT DISTINCT MaGV, Thu, Buoi, Tiet FROM tblTKB_KetQuaXep WHERE RunID = @RunID),
    GVCam AS (SELECT DISTINCT MaGV, Thu, Buoi, Tiet FROM tblTKB_GVCamTuyetDoi WHERE RunID = @RunID),
    PerSlot AS (
        SELECT g.ID, g.Thu, g.Buoi, g.Tiet,
            CASE WHEN lb.MaLop IS NULL THEN 1 ELSE 0 END AS LopTrong,
            CASE WHEN gb.MaGV IS NULL AND gc.MaGV IS NULL THEN 1 ELSE 0 END AS GVTrong
        FROM Grid g
        INNER JOIN KXD kxd ON kxd.ID = g.ID
        LEFT JOIN LopBusy lb ON lb.MaLop = kxd.MaLop AND lb.Thu = g.Thu AND lb.Buoi = g.Buoi AND lb.Tiet = g.Tiet
        LEFT JOIN GVBusy gb ON gb.MaGV = kxd.MaGV AND gb.Thu = g.Thu AND gb.Buoi = g.Buoi AND gb.Tiet = g.Tiet
        LEFT JOIN GVCam gc ON gc.MaGV = kxd.MaGV AND gc.Thu = g.Thu AND gc.Buoi = g.Buoi AND gc.Tiet = g.Tiet
    ),
    Agg AS (
        SELECT ID,
            SUM(LopTrong) AS SoSlotLopTrong,
            SUM(GVTrong) AS SoSlotGVTrong,
            SUM(CASE WHEN LopTrong = 1 AND GVTrong = 1 THEN 1 ELSE 0 END) AS SoSlotGiaoNhau
        FROM PerSlot
        GROUP BY ID
    )
    SELECT kxd.MaLop, kxd.MaMon, kxd.MaGV, gv.HoTen, kxd.SoTiet,
        a.SoSlotLopTrong, a.SoSlotGVTrong, a.SoSlotGiaoNhau,
        CASE
            WHEN a.SoSlotLopTrong <= 0 THEN N'LopHetCho'
            WHEN a.SoSlotGVTrong <= 0 THEN N'GVHetCho'
            WHEN a.SoSlotGiaoNhau <= 0 THEN N'TrungLichCoDinh'
            ELSE N'KhongRoNguyenNhan'
        END AS NguyenNhan,
        -- Chi CHO TrungLichCoDinh (giao nhau=0): liet ke tung slot lop CON TRONG va GV dang lam gi luc
        -- do — chinh la thong tin "hop khoi 1 dung luc do" ma truoc day phai dieu tra tay tung truong hop.
        (
            SELECT STRING_AGG(
                CAST(N'Thu' + CAST(ps.Thu AS NVARCHAR(2)) + N'-' + ps.Buoi + N'-T' + CAST(ps.Tiet AS NVARCHAR(2))
                    + N': GV dang ' + ISNULL(busy.MaLop, N'?') + N'-' + ISNULL(busy.MaMon, N'?') AS NVARCHAR(MAX)),
                N'; '
            )
            FROM PerSlot ps
            LEFT JOIN tblTKB_KetQuaXep busy
                ON busy.RunID = @RunID AND busy.MaGV = kxd.MaGV
                AND busy.Thu = ps.Thu AND busy.Buoi = ps.Buoi AND busy.Tiet = ps.Tiet
            WHERE ps.ID = kxd.ID AND ps.LopTrong = 1
        ) AS ChiTietTrungLich
    FROM KXD kxd
    INNER JOIN Agg a ON a.ID = kxd.ID
    LEFT JOIN tblTKB_GiaoVien gv ON gv.MaGV = kxd.MaGV
    ORDER BY
        CASE
            WHEN a.SoSlotLopTrong <= 0 THEN 1
            WHEN a.SoSlotGVTrong <= 0 THEN 2
            WHEN a.SoSlotGiaoNhau <= 0 THEN 3
            ELSE 4
        END,
        kxd.MaLop;
END
