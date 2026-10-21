CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Get_ByNhanVienSubmit]
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ROW_NUMBER() OVER (ORDER BY K.TrangThai ASC, K.KhenThuongID DESC) AS STT,
        K.KhenThuongID,
        K.DotID,
        D.TenDot,
        K.DotDuyetID,
        DD.TenDotDuyet,
        K.CongThucID,
        K.LoaiKhenThuong,
        CASE 
            WHEN K.LoaiKhenThuong = 1 THEN N'Cuộc thi KH&CN / Học thuật'
            WHEN K.LoaiKhenThuong = 2 THEN N'SHTT - Chấp nhận đơn'
            WHEN K.LoaiKhenThuong = 3 THEN N'SHTT - Cấp văn bằng'
            ELSE N'Khác'
        END AS TenLoaiKhenThuong,
        K.TenCuocThi_CongTrinh,
        K.CapDoCuocThi,
        CASE 
            WHEN K.CapDoCuocThi = 1 THEN N'Cấp quốc tế'
            WHEN K.CapDoCuocThi = 2 THEN N'Cấp khu vực quốc tế'
            WHEN K.CapDoCuocThi = 3 THEN N'Cấp quốc gia'
            WHEN K.CapDoCuocThi = 4 THEN N'Cấp khu vực (trong nước)'
            WHEN K.CapDoCuocThi = 5 THEN N'Cấp tỉnh'
            WHEN K.CapDoCuocThi = 6 THEN N'Cấp trường / Ngày hội Lạc Hồng'
            ELSE N''
        END AS TenCapDo,
        K.LoaiHinhCuocThi,
        CASE 
            WHEN K.LoaiHinhCuocThi = 1 THEN N'Khoa học & Công nghệ'
            WHEN K.LoaiHinhCuocThi = 2 THEN N'Cuộc thi học thuật'
            WHEN K.LoaiHinhCuocThi = 3 THEN N'Cuộc thi đặc thù'
            ELSE N''
        END AS TenLoaiHinh,
        K.GiaiThuong,
        CASE 
            WHEN K.GiaiThuong = 1 THEN N'Giải Nhất'
            WHEN K.GiaiThuong = 2 THEN N'Giải Nhì'
            WHEN K.GiaiThuong = 3 THEN N'Giải Ba'
            WHEN K.GiaiThuong = 4 THEN N'Khuyến khích'
            WHEN K.GiaiThuong = 5 THEN N'Báo cáo ngày hội'
            ELSE N''
        END AS TenGiaiThuong,
        K.LoaiSHTT,
        CASE 
            WHEN K.LoaiSHTT = 1 THEN N'Sáng chế / Giống cây trồng'
            WHEN K.LoaiSHTT = 2 THEN N'Giải pháp hữu ích'
            WHEN K.LoaiSHTT = 3 THEN N'Kiểu dáng công nghiệp'
            WHEN K.LoaiSHTT = 4 THEN N'Quyền tác giả'
            ELSE N''
        END AS TenLoaiSHTT,
        K.PhamViSHTT,
        K.Is_DauRaDeTaiCoSo,
        K.SoQuyetDinh_VanBang,
        CONVERT(VARCHAR(10), K.NgayBanHanh, 23) AS NgayBanHanh,
        CONVERT(VARCHAR(10), K.NgayBanHanh, 103) AS NgayBanHanhFormatted,
        K.TongTienThuong,
        K.HinhThucThanhToan,
        K.TrangThai,
        CASE 
            WHEN K.TrangThai = 1 THEN N'Lưu nháp'
            WHEN K.TrangThai = 2 THEN N'Chờ duyệt'
            WHEN K.TrangThai = 3 THEN N'Đã duyệt'
            WHEN K.TrangThai = 4 THEN N'Từ chối'
            ELSE N''
        END AS TenTrangThai,
        K.LyDoReject,
        K.GhiChu,
        K.NhanVienSubmit,
        CONVERT(VARCHAR(16), K.ThoiGianSubmit, 120) AS ThoiGianSubmit,
        STUFF((
            SELECT ', ' + TV.HoTen + ' (' + 
                CASE 
                    WHEN TV.VaiTro = 1 THEN N'Trưởng nhóm'
                    WHEN TV.VaiTro = 2 THEN N'Đồng tác giả'
                    WHEN TV.VaiTro = 3 THEN N'GVHD'
                    WHEN TV.VaiTro = 4 THEN N'Hỗ trợ SHTT'
                    ELSE N''
                END + ')'
            FROM ThiKHCN_ThanhVien TV
            WHERE TV.KhenThuongID = K.KhenThuongID AND TV.Is_Xoa = 0
            FOR XML PATH('')
        ), 1, 2, '') AS ThanhVienList
    FROM ThiKHCN_KhenThuong K
    LEFT JOIN ThiKHCN_Dot D ON K.DotID = D.DotID
    LEFT JOIN ThiKHCN_DotDuyet DD ON K.DotDuyetID = DD.DotDuyetID
    WHERE K.Is_Xoa = 0 
      AND K.NhanVienSubmit = @SYS_UserID
    ORDER BY K.TrangThai ASC, K.KhenThuongID DESC;
END;