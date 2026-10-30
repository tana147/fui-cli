CREATE PROCEDURE spAPI_TkbKetQuaXepChecklistGV
    @RunID      int,
    @MaGV       varchar(15),
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Doi chieu Dinh muc phan cong giang day cua 1 GV (co the day nhieu Lop/Mon/Khoi khac nhau —
    -- vd GV chuyen MT/TD) voi thuc te da xep.
    --
    -- FIX (2026-09-02, phat hien qua bao cao thuc te — GV day ca khoi 08 lan khoi 09, xem checklist
    -- tren RunID khoi 08 thi khoi 09 bi bao "Chua chay" du RunID 212 (khoi 09) DA CHAY XONG DAY DU):
    -- ban cu chi so sanh "khoi cua dong PCGD nay co = khoi cua RunID dang xem khong" — neu khac thi
    -- LUON bao "Chua chay", bat ke khoi do co that su co 1 RunID kha thi rieng hay khong.
    --
    -- MOC QUAN TRONG: TKB phai doi chieu theo TUAN (khai niem nghiep vu), KHONG phai theo RunID
    -- (chi la ID ky thuat cua 1 lan chay). Vi vay khi tim lich cua 1 khoi KHAC, khong duoc lay RunID
    -- kha thi MOI NHAT bat ky (co the la tuan khac) — phai tim dung RunID cua khoi do TRUNG TUAN
    -- (TuanHienTai) voi RunID dang xem. Neu khoi do chua co RunID nao kha thi cho DUNG TUAN nay thi
    -- moi thuc su la "Chua chay" (cho tuan nay).
    --
    -- FIX (2026-09-13, phat hien qua bao cao thuc te — toan bo bang "Chua chay" du RunID dang xem
    -- (vd 1263) da Feasible va co du lieu that): kien truc moi (Round 1 -> 1.5 -> 2 -> 4 deu TAI SU
    -- DUNG chung 1 RunID qua @RunIDDangXay, khong con tao RunID rieng tung khoi nua) khien cot
    -- tblTKB_ChayAutoLog.Khoi cua 1 RunID nhu vay khong con dai dien dung "khoi nao" (thuong la ''
    -- rong, vi cac lan UPDATE qua @RunIDDangXay khong dong tou cot nay) — so sanh "l.Khoi = @KhoiRun"
    -- vi vay KHONG BAO GIO dung, ke ca voi chinh lop thuoc RunID dang xem, khien moi dong roi vao
    -- nhanh tim RunID khac va bao "Chua chay" oan. Sua: kiem tra TRUC TIEP "lop nay da co dong nao
    -- trong tblTKB_KetQuaXep cua CHINH @RunID dang xem chua" thay vi so sanh Khoi — dung ban chat cau
    -- hoi can tra loi (RunID nay DA xu ly lop nay chua), khong phu thuoc cot Khoi nua.
    DECLARE @TuanHienTai INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);

    SELECT pc.MaLop, pc.MaMon, m.TenMon,
        pc.SoTietChuanTuan AS DinhMuc,
        ISNULL(kq.SoTietDaXep, 0) AS DaXep,
        ISNULL(kq.SoTietDaXep, 0) - pc.SoTietChuanTuan AS ChenhLech,
        CASE
            WHEN rr.RunIDApDung IS NULL THEN N'Chưa chạy'
            WHEN ISNULL(kq.SoTietDaXep, 0) = pc.SoTietChuanTuan THEN N'Đủ'
            WHEN ISNULL(kq.SoTietDaXep, 0) < pc.SoTietChuanTuan THEN N'Thiếu'
            ELSE N'Dư'
        END AS KetQua,
        CASE WHEN rr.RunIDApDung IS NOT NULL AND rr.RunIDApDung <> @RunID
             THEN N'Xem ở RunID ' + CAST(rr.RunIDApDung AS VARCHAR(10))
             ELSE NULL END AS GhiChuRunIDKhac,
        qt.QuyTacInfo
    FROM tblTKB_PhanCongGiangDay pc
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = pc.MaMon
    CROSS APPLY (
        SELECT CASE
            WHEN EXISTS (SELECT 1 FROM tblTKB_KetQuaXep k0 WHERE k0.RunID = @RunID AND k0.MaLop = pc.MaLop)
                THEN @RunID
            ELSE (
                SELECT MAX(RunID) FROM tblTKB_ChayAutoLog
                WHERE Khoi = l.Khoi AND Enable = 1 AND KhaThi = 1
                  AND (@TuanHienTai IS NULL OR TuanHienTai = @TuanHienTai)
            )
        END AS RunIDApDung
    ) rr
    OUTER APPLY (
        SELECT COUNT(*) AS SoTietDaXep
        FROM tblTKB_KetQuaXep k
        WHERE k.RunID = rr.RunIDApDung AND k.MaGV = @MaGV AND k.MaLop = pc.MaLop AND k.MaMon = pc.MaMon
    ) kq
    OUTER APPLY (
        SELECT STRING_AGG(CAST(LoaiQuyTac AS NVARCHAR(50)), N', ') AS QuyTacInfo
        FROM tblTKB_MonQuyTac
        WHERE Enable = 1 AND MaMon = pc.MaMon AND (Khoi IS NULL OR Khoi = l.Khoi)
    ) qt
    WHERE pc.MaGV = @MaGV AND pc.Enable = 1 AND pc.HocKy = 'HK1' AND l.Enable = 1
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    ORDER BY
        CASE
            WHEN rr.RunIDApDung IS NULL THEN 2
            WHEN ISNULL(kq.SoTietDaXep, 0) <> pc.SoTietChuanTuan THEN 0
            ELSE 1
        END,
        pc.MaLop, m.TenMon
END
