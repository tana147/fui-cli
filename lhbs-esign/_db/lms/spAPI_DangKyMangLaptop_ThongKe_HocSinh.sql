CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongKe_HocSinh]
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

    SELECT h.HocSinhID
         , h.HoTen
         , dk.TenLop
         , COUNT(*) AS SoLuot
         , SUM(CASE WHEN h.IsViPham = 1 THEN 1 ELSE 0 END) AS SoLanViPham
    FROM dbo.tblDangKyMangLaptop_HocSinh h
    INNER JOIN dbo.tblDangKyMangLaptop dk ON dk.DangKyID = h.DangKyID AND dk.Enable = 1
    WHERE h.Enable = 1
      AND dk.NienKhoa = @NienKhoa
      AND (@TuanHocID = 0 OR dk.TuanHocID = @TuanHocID)
      AND dk.NgayApDung >= @TuNgay
      AND dk.NgayApDung <= @DenNgay
    GROUP BY h.HocSinhID, h.HoTen, dk.TenLop
    ORDER BY SoLuot DESC, h.HoTen;
END
