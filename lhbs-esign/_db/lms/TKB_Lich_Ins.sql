CREATE PROCEDURE dbo.TKB_Lich_Ins
    @NienKhoa VARCHAR(20), @LopHocID INT, @Lop NVARCHAR(200) = NULL,
    @Thu INT, @BuoiID INT, @Tiet INT, @MonHocID INT,
    @MaMon VARCHAR(50) = NULL, @TenMonHoc NVARCHAR(200) = NULL,
    @GiaoVienID VARCHAR(50) = NULL, @GhiChu NVARCHAR(MAX) = NULL,
    @MaDonVi INT = NULL, @NguoiTao VARCHAR(50) = NULL, @CapHoc INT = 0,
    @TuanID INT = 0, @HocKy INT = NULL, @ThoiKhoaBieu_CalenID VARCHAR(50) = ''
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.tblTKB_Lich
      (NienKhoa, CapHoc, LopHocID, Lop, Thu, BuoiID, Tiet, MonHocID, MaMon, TenMonHoc,
       GiaoVienID, GhiChu, MaDonVi, NgayTao, NguoiTao, HocKy, TuanID, ThoiKhoaBieu_CalenID)
    VALUES
      (@NienKhoa, @CapHoc, @LopHocID, @Lop, @Thu, @BuoiID, @Tiet, @MonHocID, @MaMon, @TenMonHoc,
       @GiaoVienID, @GhiChu, @MaDonVi, GETDATE(), @NguoiTao, @HocKy,
       NULLIF(@TuanID, 0), NULLIF(@ThoiKhoaBieu_CalenID, ''));
END
