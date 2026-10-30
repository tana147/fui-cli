CREATE PROCEDURE spAPI_TkbKetQuaXepChecklist
    @RunID      int,
    @MaLop      varchar(10),
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Doi chieu Dinh muc (tblTKB_PhanCongGiangDay) voi thuc te da xep (tblTKB_KetQuaXep cua RunID
    -- nay) cho 1 lop — dung logic da kiem chung thu cong nhieu lan trong phien 2026-08-27/28 (vu
    -- 41/40 tiet do JA/BTHT). Kem quy tac dang ap dung (tblTKB_MonQuyTac) cho moi mon — theo
    -- Khoi cua lop hoac ap dung moi khoi (Khoi IS NULL).
    --
    -- @TuanHienTai (2026-08-28): dinh muc thay doi theo tuan (R18 — vd BTHT/STEM/JA khac nhau moi
    -- tuan), nen PHAI loc PCGD dung tuan cua RunID nay (luu trong tblTKB_ChayAutoLog.TuanHienTai) —
    -- KHONG duoc liet ke tat ca cac doan TuanApDungTu/Den nhu truoc (gay hien thi TRUNG mon nhieu
    -- dong voi dinh muc khac nhau, vd "Bo tro hoc tap" x3, kho hieu cho nguoi dung).
    DECLARE @Khoi varchar(2) = (SELECT Khoi FROM tblTKB_Lop WHERE MaLop = @MaLop);
    DECLARE @TuanHienTai INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);

    SELECT pc.MaMon, m.TenMon,
        pc.SoTietChuanTuan AS DinhMuc,
        ISNULL(kq.SoTietDaXep, 0) AS DaXep,
        ISNULL(kq.SoTietDaXep, 0) - pc.SoTietChuanTuan AS ChenhLech,
        CASE
            WHEN ISNULL(kq.SoTietDaXep, 0) = pc.SoTietChuanTuan THEN N'Đủ'
            WHEN ISNULL(kq.SoTietDaXep, 0) < pc.SoTietChuanTuan THEN N'Thiếu'
            ELSE N'Dư'
        END AS KetQua,
        qt.QuyTacInfo
    FROM tblTKB_PhanCongGiangDay pc
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = pc.MaMon
    LEFT JOIN (
        SELECT MaMon, COUNT(*) AS SoTietDaXep
        FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID AND MaLop = @MaLop
        GROUP BY MaMon
    ) kq ON kq.MaMon = pc.MaMon
    OUTER APPLY (
        SELECT STRING_AGG(CAST(LoaiQuyTac AS NVARCHAR(50)), N', ') AS QuyTacInfo
        FROM tblTKB_MonQuyTac
        WHERE Enable = 1 AND MaMon = pc.MaMon AND (Khoi IS NULL OR Khoi = @Khoi)
    ) qt
    WHERE pc.MaLop = @MaLop AND pc.Enable = 1 AND pc.HocKy = 'HK1'
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    ORDER BY CASE
            WHEN ISNULL(kq.SoTietDaXep, 0) <> pc.SoTietChuanTuan THEN 0 ELSE 1
        END, m.TenMon
END