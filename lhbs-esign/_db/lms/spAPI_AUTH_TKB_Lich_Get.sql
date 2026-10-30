CREATE PROCEDURE dbo.spAPI_AUTH_TKB_Lich_Get
    @NienKhoa VARCHAR(20) = NULL, @CapHoc INT = NULL, @LopHocID INT = 0,
    @GiaoVienID VARCHAR(50) = '', @TuanID INT = NULL, @HocKy INT = 0, @MaDonVi INT = NULL,
    @sys_UserID VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT L.TKBLichID AS SlotID, L.TKBLichID,
        L.NienKhoa, L.HocKy, L.TuanID,
        L.CapHoc, L.MaDonVi,
        L.LopHocID, L.Lop,
        L.Thu, L.BuoiID, L.Tiet,
        L.MonHocID, L.MaMon, L.TenMonHoc,
        L.GiaoVienID, L.GhiChu,
        L.GiaoVienDayThayID, L.GhiChuDayThay, L.TinhTrangXepLich,
        L.ThoiKhoaBieu_CalenID,
        T.Tuan, T.NgayBatDau, T.NgayKetThuc, L.LoaiTKB
    FROM dbo.tblTKB_Lich L
    LEFT JOIN dbo.tblTuanHocTap T ON T.TuanHocID = L.TuanID
    WHERE (@NienKhoa IS NULL OR L.NienKhoa = @NienKhoa)
      AND (@CapHoc IS NULL OR L.CapHoc = @CapHoc)
      AND (@LopHocID = 0 OR L.LopHocID = @LopHocID)
      AND (@GiaoVienID = '' OR L.GiaoVienID = @GiaoVienID)
      AND (@MaDonVi IS NULL OR L.MaDonVi = @MaDonVi)
      AND (@HocKy = 0 OR L.HocKy = @HocKy)
      AND (@TuanID IS NULL OR L.TuanID = @TuanID);
END
