CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Del_ByBaoCao_ChiTietID]
    @BaoCao_ChiTietID INT
  , @SYS_USERID       VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblBaoCao_ChiTiet
    SET    Enable = 0
         , NguoiCapNhat = @SYS_USERID
         , NgayCapNhat = GETDATE()
    WHERE
           BaoCao_ChiTietID = @BaoCao_ChiTietID;
END;