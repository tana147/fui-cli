CREATE PROCEDURE dbo.spAPI_SoGVCNGet
    @url1_SoGVCNID varchar(10),
    @sys_UserID varchar(10),
    @sys_SystemRight varchar(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        s.SoGVCNID,
        s.NienKhoa,
        s.LopID,
        l.TenLop,
        l.KhoiID,
        s.CapID,
        s.GiaoVienID,
        s.TrangThai,
        s.ThongTinLop,
        s.ChiTieu,
        s.SiSo,
        s.GiaoVienBoMon,
        s.BanDaiDienCMHS,
        s.CanBoLop,
        s.HuongNghiep,
        s.SubmitTime,
        s.UpdateTime
    FROM dbo.tblSoGVCN s
    INNER JOIN dbo.tblLop l ON l.LopID = s.LopID AND l.NienKhoa = s.NienKhoa
    WHERE s.SoGVCNID = @url1_SoGVCNID
      AND s.Enable = 1;

    SELECT
        KeHoachThangID,
        SoGVCNID,
        Thang,
        ChuDe,
        MucTieu,
        NhiemVu,
        KeHoachTuan,
        DanhGia
    FROM dbo.tblSoGVCNKeHoachThang
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY Thang;

    SELECT
        ChiTieuID,
        SoGVCNID,
        LoaiChiTieu,
        MatGiaoDuc,
        YeuCau,
        Tot,
        Kha,
        Dat,
        ChuaDat,
        BienPhap,
        HSXS,
        HSG,
        NoiDung,
        GhiChu,
        RowIndex
    FROM dbo.tblSoGVCNChiTieu
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY LoaiChiTieu, RowIndex;

    SELECT
        TheoDoiRenLuyenID,
        SoGVCNID,
        HSLopID,
        Thang,
        NoiDung,
        BienPhap,
        KetQua
    FROM dbo.tblSoGVCNTheoDoiRenLuyen
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY HSLopID, Thang;

    SELECT
        NhanXetSoLienLacID,
        SoGVCNID,
        HSLopID,
        Thang,
        NhanXet,
        DeNghiPHHS
    FROM dbo.tblSoGVCNNhanXetSoLienLac
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY HSLopID, Thang;

    SELECT
        SiSoID,
        SoGVCNID,
        MocDanhMucID,
        Moc,
        SiSo,
        Nam,
        ChuyenDi,
        ChuyenDen
    FROM dbo.tblSoGVCNSiSo
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY CASE Moc WHEN N'Đầu năm' THEN 1 WHEN N'Cuối kì 1' THEN 2 WHEN N'Cuối kì 2' THEN 3 ELSE 99 END, Moc;

    SELECT
        GiaoVienBoMonID,
        SoGVCNID,
        MonHocID,
        BoMon,
        HocKy,
        GiaoVienID,
        GiaoVien,
        ThayDoi,
        RowIndex
    FROM dbo.tblSoGVCNGiaoVienBoMon
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY RowIndex;

    SELECT
        BanDaiDienCMHSID,
        SoGVCNID,
        NhiemVuDanhMucID,
        STT,
        HSLopID,
        HocSinhID,
        MaHocSinh,
        HocSinh,
        ChaMe,
        NgheNghiep,
        DienThoai,
        NhiemVu,
        GhiChu,
        RowIndex
    FROM dbo.tblSoGVCNBanDaiDienCMHS
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY RowIndex;

    SELECT
        CanBoLopID,
        SoGVCNID,
        ChucVuDanhMucID,
        STT,
        HSLopID,
        HocSinhID,
        MaHocSinh,
        HocSinh,
        ChucVu,
        GhiChu,
        RowIndex
    FROM dbo.tblSoGVCNCanBoLop
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY RowIndex;

    SELECT
        HuongNghiepID,
        SoGVCNID,
        MonThiTNDanhMucID,
        STT,
        HSLopID,
        HocSinhID,
        MaHocSinh,
        HoTen,
        MonThiTN,
        KQTracNghiem,
        RowIndex
    FROM dbo.tblSoGVCNHuongNghiep
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY RowIndex;

    SELECT
        ToNhomHocSinhID,
        SoGVCNID,
        HSLopID,
        HocSinhID,
        MaHocSinh,
        HocSinh,
        ToNhom,
        NhiemVu,
        Ban,
        RowIndex
    FROM dbo.tblSoGVCNToNhomHocSinh
    WHERE SoGVCNID = @url1_SoGVCNID
      AND Enable = 1
    ORDER BY RowIndex;
END
