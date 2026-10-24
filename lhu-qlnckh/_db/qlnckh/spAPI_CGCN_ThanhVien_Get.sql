CREATE PROCEDURE [dbo].[spAPI_CGCN_ThanhVien_Get]
    @CGCNID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CGCN_ThanhVienID,
        CGCNID,
        VaiTro = ISNULL(VaiTro, 2),
        TenVaiTro = ISNULL(TenVaiTro, CASE VaiTro WHEN 1 THEN N'Chủ nhiệm' WHEN 3 THEN N'Thư ký' ELSE N'Thành viên' END),
        Is_NhanVien = ISNULL(Is_NhanVien, 1),
        Is_SinhVien = ISNULL(Is_SinhVien, 0),
        MaDinhDanh = ISNULL(MaDinhDanh, ''),
        HoTen,
        Email = ISNULL(Email, ''),
        TenPhongBan = ISNULL(TenPhongBan, ''),
        TyLeDongGop = ISNULL(TyLeDongGop, 0)
    FROM dbo.ChuyenGiaoCongNghe_ThanhVien
    WHERE CGCNID = @CGCNID AND Is_Xoa = 0
    ORDER BY VaiTro ASC, CGCN_ThanhVienID ASC;
END;
