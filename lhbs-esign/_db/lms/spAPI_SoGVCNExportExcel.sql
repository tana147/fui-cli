CREATE   PROCEDURE dbo.spAPI_SoGVCNExportExcel
    @SoGVCNID int,
    @sys_UserID varchar(20),
    @sys_SystemRight int
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.SoGVCNID,
        s.NienKhoa,
        l.TenLop,
        l.KhoiID,
        s.TrangThai,
        s.ThongTinLop,
        s.ChiTieu,
        s.SiSo,
        s.GiaoVienBoMon,
        s.BanDaiDienCMHS,
        s.CanBoLop,
        s.HuongNghiep
    FROM dbo.tblSoGVCN s
    INNER JOIN dbo.tblLop l ON l.LopID = s.LopID AND l.NienKhoa = s.NienKhoa
    WHERE s.SoGVCNID = @SoGVCNID
      AND s.Enable = 1;

    SELECT Thang, ChuDe, MucTieu, NhiemVu, KeHoachTuan, DanhGia
    FROM dbo.tblSoGVCNKeHoachThang
    WHERE SoGVCNID = @SoGVCNID
      AND Enable = 1
    ORDER BY Thang;
END