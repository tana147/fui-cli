CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_HocSinh_Get]
    @DangKyID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT h.DangKyHocSinhID, h.HocSinhID, hsl.SoDanhBo, h.HoTen, h.LoaiThietBi, h.IsViPham, h.GhiChuViPham
    FROM dbo.tblDangKyMangLaptop_HocSinh h
    INNER JOIN dbo.tblDangKyMangLaptop dk ON dk.DangKyID = h.DangKyID
    LEFT JOIN dbo.tblHocSinhLop hsl ON hsl.HocSinhID = h.HocSinhID AND hsl.LopID = dk.LopID AND (hsl.NienKhoa = dk.NienKhoa OR dk.NienKhoa IS NULL) AND hsl.Enable = 1
    WHERE h.DangKyID = @DangKyID AND h.Enable = 1
    ORDER BY h.HoTen;
END