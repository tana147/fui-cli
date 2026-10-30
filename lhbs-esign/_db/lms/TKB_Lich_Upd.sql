CREATE PROCEDURE dbo.TKB_Lich_Upd
    @TKBLichID INT, @NienKhoa VARCHAR(20) = NULL, @LopHocID INT = NULL,
    @Lop NVARCHAR(200) = NULL, @Thu INT = NULL, @BuoiID INT = NULL, @Tiet INT = NULL,
    @MonHocID INT = NULL, @MaMon VARCHAR(50) = NULL, @TenMonHoc NVARCHAR(200) = NULL,
    @GiaoVienID VARCHAR(50) = NULL, @GhiChu NVARCHAR(MAX) = NULL, @MaDonVi INT = NULL,
    @CapHoc INT = NULL, @HocKy INT = NULL, @TuanID INT = NULL, @ThoiKhoaBieu_CalenID VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.tblTKB_Lich
    SET NienKhoa = ISNULL(@NienKhoa, NienKhoa), CapHoc = ISNULL(@CapHoc, CapHoc),
        LopHocID = ISNULL(@LopHocID, LopHocID), Lop = ISNULL(@Lop, Lop),
        Thu = ISNULL(@Thu, Thu), BuoiID = ISNULL(@BuoiID, BuoiID), Tiet = ISNULL(@Tiet, Tiet),
        MonHocID = ISNULL(@MonHocID, MonHocID), MaMon = ISNULL(@MaMon, MaMon),
        TenMonHoc = ISNULL(@TenMonHoc, TenMonHoc), GiaoVienID = ISNULL(@GiaoVienID, GiaoVienID),
        GhiChu = ISNULL(@GhiChu, GhiChu), MaDonVi = ISNULL(@MaDonVi, MaDonVi),
        HocKy = ISNULL(@HocKy, HocKy), TuanID = ISNULL(@TuanID, TuanID),
        ThoiKhoaBieu_CalenID = ISNULL(@ThoiKhoaBieu_CalenID, ThoiKhoaBieu_CalenID)
    WHERE TKBLichID = @TKBLichID;
END
