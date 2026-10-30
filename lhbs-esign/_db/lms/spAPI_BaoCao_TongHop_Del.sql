
CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Del]
    @BaoCaoID   INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE tblBaoCao
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           BaoCaoID = @BaoCaoID;
END;

