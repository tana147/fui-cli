CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_ChiTiet_Upd]
    @KyNang_MonHoc_ChiTietID INT
  , @TenKyNang               NVARCHAR(200)
  , @MoTaKyNang              NVARCHAR(1000)
  , @SYS_USERID              VARCHAR(9)
AS
BEGIN
    UPDATE tblEL_KyNang_MonHoc_ChiTiet
    SET    TenKyNang = @TenKyNang
         , MoTaKyNang = @MoTaKyNang
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           KyNang_MonHoc_ChiTietID = @KyNang_MonHoc_ChiTietID;
END;