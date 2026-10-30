CREATE PROCEDURE dbo.spAPI_SoGVCN_LichSuChinhSua_FilterInit
    @NienKhoa INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Danh sách Khối
    SELECT KhoiID, TenKhoiHoc, CapID
    FROM dbo.tblKhoi
    WHERE Enable = 1
    ORDER BY CapID, KhoiID;

    -- 2. Danh sách Lớp kèm GVCN
    SELECT l.LopID, l.TenLop, l.KhoiID,
           CASE 
               WHEN l.KhoiID BETWEEN 1 AND 5 THEN 1
               WHEN l.KhoiID BETWEEN 6 AND 9 THEN 2
               ELSE 3 
           END AS CapID,
           l.GVCN,
           RTRIM(ISNULL(gv.HoGV, '')) + ' ' + RTRIM(ISNULL(gv.TenGV, '')) AS HoTenGVCN
    FROM dbo.tblLop l
    LEFT JOIN dbo.tblGiaoVien gv ON RTRIM(l.GVCN) = RTRIM(gv.GiaoVienID)
    WHERE l.NienKhoa = @NienKhoa AND l.Enable = 1
    ORDER BY l.KhoiID, l.TenLop;
END;