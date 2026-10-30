
CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Upd]
    @BaoCaoID   INT
  , @MonHocID   INT
  , @TenBaoCao  NVARCHAR(400)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE tblBaoCao
    SET    TenBaoCao = @TenBaoCao
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           BaoCaoID = @BaoCaoID;
END;

