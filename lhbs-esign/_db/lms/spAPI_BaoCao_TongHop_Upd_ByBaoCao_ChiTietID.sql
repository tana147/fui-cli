CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Upd_ByBaoCao_ChiTietID]
    @BaoCao_ChiTietID INT
  , @HocKi            VARCHAR(50)
  , @JSON_BaoCao      NVARCHAR(MAX)
  , @Url_BaoCao       VARCHAR(200)
  , @TenBaoCao_ChiTiet NVARCHAR(200)
  , @SYS_USERID       VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblBaoCao_ChiTiet
    SET    HocKi = @HocKi
         , JSON_BaoCao = @JSON_BaoCao
         , Url_BaoCao = @Url_BaoCao
		 , TenBaoCao_ChiTiet = @TenBaoCao_ChiTiet
         , NguoiCapNhat = @SYS_USERID
         , NgayCapNhat = GETDATE()
    WHERE
           BaoCao_ChiTietID = @BaoCao_ChiTietID;

END;