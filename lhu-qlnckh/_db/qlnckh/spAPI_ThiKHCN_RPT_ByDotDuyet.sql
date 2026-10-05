CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_RPT_ByDotDuyet]
    @DotDuyetID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ROW_NUMBER() OVER (ORDER BY K.KhenThuongID ASC, TV.VaiTro ASC, TV.ThanhVienID ASC) AS STT,
        TV.HoTen,
        TV.MaDinhDanh,
        CASE 
            WHEN TV.VaiTro = 1 THEN N'Tác giả chính / Trưởng nhóm'
            WHEN TV.VaiTro = 2 THEN N'Đồng tác giả'
            WHEN TV.VaiTro = 3 THEN N'Giảng viên hướng dẫn'
            WHEN TV.VaiTro = 4 THEN N'Cán bộ hỗ trợ SHTT'
            ELSE N''
        END AS VaiTro,
        TV.TenPhongBan,
        TV.SoTaiKhoan,
        TV.NganHang,
        TV.TenChuTaiKhoan,
        TV.SoTienThuong,
        K.TenCuocThi_CongTrinh,
        CASE 
            WHEN K.LoaiKhenThuong = 1 THEN 
                CASE 
                    WHEN K.GiaiThuong = 1 THEN N'Giải Nhất'
                    WHEN K.GiaiThuong = 2 THEN N'Giải Nhì'
                    WHEN K.GiaiThuong = 3 THEN N'Giải Ba'
                    WHEN K.GiaiThuong = 4 THEN N'Khuyến khích'
                    WHEN K.GiaiThuong = 5 THEN N'Báo cáo ngày hội'
                    ELSE N''
                END
            WHEN K.LoaiKhenThuong = 2 THEN N'Chấp nhận đơn hợp lệ'
            WHEN K.LoaiKhenThuong = 3 THEN N'Cấp văn bằng bảo hộ'
            ELSE N''
        END AS TenGiai_HinhThuc,
        CASE 
            WHEN K.CapDoCuocThi = 1 THEN N'Cấp quốc tế'
            WHEN K.CapDoCuocThi = 2 THEN N'Cấp khu vực quốc tế'
            WHEN K.CapDoCuocThi = 3 THEN N'Cấp quốc gia'
            WHEN K.CapDoCuocThi = 4 THEN N'Cấp khu vực (trong nước)'
            WHEN K.CapDoCuocThi = 5 THEN N'Cấp tỉnh'
            WHEN K.CapDoCuocThi = 6 THEN N'Cấp trường / Ngày hội Lạc Hồng'
            ELSE N''
        END AS TenCapDo,
        K.SoQuyetDinh_VanBang,
        CONVERT(VARCHAR(10), K.NgayBanHanh, 103) AS NgayBanHanh,
        DD.TenDotDuyet
    FROM ThiKHCN_ThanhVien TV
    INNER JOIN ThiKHCN_KhenThuong K ON TV.KhenThuongID = K.KhenThuongID
    LEFT JOIN ThiKHCN_DotDuyet DD ON K.DotDuyetID = DD.DotDuyetID
    WHERE K.Is_Xoa = 0 
      AND TV.Is_Xoa = 0
      AND K.DotDuyetID = @DotDuyetID
      AND K.TrangThai = 3 -- Đã duyệt
    ORDER BY K.KhenThuongID ASC, TV.VaiTro ASC, TV.ThanhVienID ASC;
END;