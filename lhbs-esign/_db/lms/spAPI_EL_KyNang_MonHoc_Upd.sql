CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_Upd]
    @MonHocID        INT
  , @NhomKyNang      NVARCHAR(200)
  , @KyNang_MonHocID INT
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblEL_KyNang_MonHoc
    SET    MonHocID = @MonHocID
         , NhomKyNang = @NhomKyNang
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           KyNang_MonHocID = @KyNang_MonHocID;
END;