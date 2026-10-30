CREATE PROCEDURE [dbo].[spAPI_TemplateBangDiemChiTiet_Del]
    @CotDiemID          INT
  , @TemplateBangDiemID INT
  , @SYS_USERID         VARCHAR(9)
AS
BEGIN
    UPDATE dbo.TemplateBangDiemChiTiet
    SET    [Enable] = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           TemplateBangDiemID = @TemplateBangDiemID
      AND  CotDiemID           = @CotDiemID;
END;
