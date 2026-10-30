CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Upd_Chot_BaoCao]
    @BaoCao_ChiTietID INT
  , @JSON_BaoCao      NVARCHAR(MAX)
  , @SYS_USERID       VARCHAR(9)
AS
BEGIN
    UPDATE tblBaoCao_ChiTiet
    SET    IsChotBaoCao = 1
         , JSON_BaoCao = @JSON_BaoCao
         , NgayChot = GETDATE()
         , NguoiChot = @SYS_USERID
    WHERE
           BaoCao_ChiTietID = @BaoCao_ChiTietID;
END;

