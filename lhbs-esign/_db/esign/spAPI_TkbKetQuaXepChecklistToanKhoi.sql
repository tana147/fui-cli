CREATE PROCEDURE spAPI_TkbKetQuaXepChecklistToanKhoi
    @RunID      int,
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;
    -- Ban toan-khoi cua spAPI_TkbKetQuaXepChecklist — tra doi chieu Dinh muc/Da xep cho TAT CA
    -- lop thuoc khoi cua RunID nay trong 1 lan goi (dung cho che do "Xem toan khoi", tranh N lan
    -- goi API rieng cho tung lop).
    -- @TuanHienTai (2026-08-28): dinh muc thay doi theo tuan (R18) — loc PCGD dung tuan cua RunID
    -- nay (tblTKB_ChayAutoLog.TuanHienTai), tranh liet ke trung mon nhieu dong nhu truoc khi sua.
    DECLARE @KhoiRun VARCHAR(50) = (SELECT Khoi FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);
    DECLARE @TuanHienTai INT = (SELECT TuanHienTai FROM tblTKB_ChayAutoLog WHERE RunID = @RunID);

    SELECT pc.MaLop, pc.MaMon, m.TenMon,
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
    INNER JOIN tblTKB_Lop l ON l.MaLop = pc.MaLop
    LEFT JOIN tblTKB_MonHoc m ON m.MaMon = pc.MaMon
    LEFT JOIN (
        SELECT MaLop, MaMon, COUNT(*) AS SoTietDaXep
        FROM tblTKB_KetQuaXep
        WHERE RunID = @RunID
        GROUP BY MaLop, MaMon
    ) kq ON kq.MaLop = pc.MaLop AND kq.MaMon = pc.MaMon
    OUTER APPLY (
        SELECT STRING_AGG(CAST(LoaiQuyTac AS NVARCHAR(50)), N', ') AS QuyTacInfo
        FROM tblTKB_MonQuyTac
        WHERE Enable = 1 AND MaMon = pc.MaMon AND (Khoi IS NULL OR Khoi = l.Khoi)
    ) qt
    WHERE l.Khoi = @KhoiRun AND l.Enable = 1 AND pc.Enable = 1 AND pc.HocKy = 'HK1'
      AND (@TuanHienTai IS NULL OR pc.TuanApDungTu IS NULL OR @TuanHienTai >= pc.TuanApDungTu)
      AND (@TuanHienTai IS NULL OR pc.TuanApDungDen IS NULL OR @TuanHienTai <= pc.TuanApDungDen)
      AND (@TuanHienTai IS NULL OR pc.ApDungTuanChan IS NULL OR pc.ApDungTuanChan = CASE WHEN @TuanHienTai % 2 = 0 THEN 1 ELSE 0 END)
    ORDER BY pc.MaLop, CASE
            WHEN ISNULL(kq.SoTietDaXep, 0) <> pc.SoTietChuanTuan THEN 0 ELSE 1
        END, m.TenMon
END