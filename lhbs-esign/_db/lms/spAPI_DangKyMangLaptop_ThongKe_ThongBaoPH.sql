CREATE PROCEDURE [dbo].[spAPI_DangKyMangLaptop_ThongKe_ThongBaoPH]
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

    SELECT dk.LopID
         , dk.TenLop
         , dk.NgayApDung
         , COUNT(*) AS SoLuot
         , CAST(CASE WHEN MIN(CAST(dk.IsDaThongBaoPH AS INT)) = 1 THEN 1 ELSE 0 END AS BIT) AS DaThongBaoHet
         , MAX(dk.TenGiaoVienDangKy) AS GiaoVienGanNhat
    FROM dbo.tblDangKyMangLaptop dk
    WHERE dk.Enable = 1
      AND dk.NienKhoa = @NienKhoa
      AND (@TuanHocID = 0 OR dk.TuanHocID = @TuanHocID)
      AND dk.NgayApDung >= @TuNgay
      AND dk.NgayApDung <= @DenNgay
    GROUP BY dk.LopID, dk.TenLop, dk.NgayApDung
    ORDER BY dk.NgayApDung DESC, dk.TenLop;
END
