CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_CongThuc_Get]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        CongThucID,
        MaCongThuc,
        TenCongThuc,
        NhomKhenThuong,
        CapDo,
        GiaiThuong,
        MucThuong_NhomTacGia,
        MucThuong_GVHD,
        MucThuong_CanBoHoTro,
        HeSoNhan,
        DieuKhoanApDung,
        QuyetDinhApDung,
        GhiChu
    FROM ThiKHCN_CongThucKhenThuong
    WHERE Is_Xoa = 0
    ORDER BY NhomKhenThuong ASC, CapDo ASC, GiaiThuong ASC;
END;