CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Get_BaoCaoID_HocKi_CapID]
    @BaoCaoID INT
  , @HocKi    NVARCHAR(50)
  , @CapID    INT
  , @NienKhoa INT
AS
BEGIN
    SELECT BaoCaoID
         , MonHocID
         , TenBaoCao
    FROM
           dbo.tblBaoCao
    WHERE
           CapID   = @CapID
      AND  BaoCaoID = @BaoCaoID
      AND  Enable   = 1;

    SELECT BaoCao_ChiTietID
         , BaoCaoID
         , HocKi
         , JSON_BaoCao
         , Url_BaoCao
         , IsChotBaoCao
         , NguoiChot
         , gv.HoGV + ' ' + gv.TenGV                AS HoTenNguoiChot
         , FORMAT(NgayChot, 'dd/MM/yyyy hh:mm:ss') AS NgayChot
    FROM
           dbo.tblBaoCao_ChiTiet     ct
           LEFT JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = ct.NguoiChot
    WHERE
           BaoCaoID   = @BaoCaoID
      AND  HocKi       = @HocKi
      AND  ct.Enable   = 1
      AND  ct.NienKhoa = @NienKhoa;
END;
