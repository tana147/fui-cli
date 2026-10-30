CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_ChiTiet_Del]
    @KyNang_MonHoc_ChiTietID INT
  , @SYS_USERID              VARCHAR(9)
AS
BEGIN
    UPDATE tblEL_KyNang_MonHoc_ChiTiet
    SET    IsDeleted = 1
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           KyNang_MonHoc_ChiTietID = @KyNang_MonHoc_ChiTietID;
END;