CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Get_ByID]
    @KhenThuongID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Set 0: Thông tin hồ sơ
    SELECT 
        K.KhenThuongID,
        K.DotID,
        D.TenDot,
        K.DotDuyetID,
        DD.TenDotDuyet,
        K.CongThucID,
        CT.TenCongThuc,
        CT.MucThuong_NhomTacGia,
        CT.MucThuong_GVHD,
        CT.MucThuong_CanBoHoTro,
        K.LoaiKhenThuong,
        K.TenCuocThi_CongTrinh,
        K.CapDoCuocThi,
        K.LoaiHinhCuocThi,
        K.GiaiThuong,
        K.LoaiSHTT,
        K.PhamViSHTT,
        K.Is_DauRaDeTaiCoSo,
        K.SoQuyetDinh_VanBang, K.NoiCapVanBang,
        CONVERT(VARCHAR(10), K.NgayBanHanh, 23) AS NgayBanHanh,
        CONVERT(VARCHAR(10), K.NgayBanHanh, 103) AS NgayBanHanhFormatted,
        K.TongTienThuong,
        K.HinhThucThanhToan,
        K.TrangThai,
        K.LyDoReject,
        K.GhiChu,
        K.NhanVienSubmit,
        CONVERT(VARCHAR(16), K.ThoiGianSubmit, 120) AS ThoiGianSubmit,
        K.NguoiDuyet,
        CONVERT(VARCHAR(16), K.ThoiGianDuyet, 120) AS ThoiGianDuyet
    FROM ThiKHCN_KhenThuong K
    LEFT JOIN ThiKHCN_Dot D ON K.DotID = D.DotID
    LEFT JOIN ThiKHCN_DotDuyet DD ON K.DotDuyetID = DD.DotDuyetID
    LEFT JOIN ThiKHCN_CongThucKhenThuong CT ON K.CongThucID = CT.CongThucID
    WHERE K.KhenThuongID = @KhenThuongID;

    -- Set 1: Danh sách thành viên (Tác giả, GVHD, Cán bộ)
    SELECT 
        ThanhVienID,
        KhenThuongID,
        VaiTro,
        Is_NhanVien,
        Is_SinhVien,
        MaDinhDanh,
        HoTen,
        Email,
        TenPhongBan,
        SoTaiKhoan,
        NganHang,
        TenChuTaiKhoan,
        TyLeDongGop,
        SoTienThuong,
        Is_DaiDienNhanTien
    FROM ThiKHCN_ThanhVien
    WHERE KhenThuongID = @KhenThuongID AND Is_Xoa = 0
    ORDER BY VaiTro ASC, ThanhVienID ASC;

    -- Set 2: Danh sách file minh chứng
    SELECT 
        KhenThuongFileID,
        KhenThuongID,
        FileID,
        FileName,
        DinhDangFile,
        LoaiMinhChung,
        MoTa
    FROM ThiKHCN_File
    WHERE KhenThuongID = @KhenThuongID AND Is_Xoa = 0;
END;