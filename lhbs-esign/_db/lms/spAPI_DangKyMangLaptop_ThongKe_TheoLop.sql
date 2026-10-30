CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongKe_TheoLop]
    @NienKhoa         INT
  , @TuanHocID        INT
  , @TuNgay           DATE
  , @DenNgay          DATE
  , @sys_SystemRight  INT
  , @sys_FunctionRight VARCHAR(2000)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT (@sys_SystemRight IN (3, 4, 9) OR CHARINDEX('[QS]', ISNULL(@sys_FunctionRight, N'')) > 0)
    BEGIN
        RAISERROR(N'Bạn không có quyền xem chức năng này.', 16, 1)
        RETURN
    END

    SELECT dk.TenLop
         , dk.KhoiID
         , dk.TenGiaoVienDangKy
         , COUNT(*) AS SoLuot
         , SUM(hs.SoHocSinh) AS SoLuotHocSinh
    FROM dbo.tblDangKyMangLaptop dk
    CROSS APPLY (
        SELECT COUNT(*) AS SoHocSinh FROM dbo.tblDangKyMangLaptop_HocSinh h WHERE h.DangKyID = dk.DangKyID AND h.Enable = 1
    ) hs
    WHERE dk.Enable = 1
      AND dk.NienKhoa = @NienKhoa
      AND (@TuanHocID = 0 OR dk.TuanHocID = @TuanHocID)
      AND dk.NgayApDung >= @TuNgay
      AND dk.NgayApDung <= @DenNgay
    GROUP BY dk.TenLop, dk.KhoiID, dk.TenGiaoVienDangKy
    ORDER BY dk.KhoiID, dk.TenLop;
END
