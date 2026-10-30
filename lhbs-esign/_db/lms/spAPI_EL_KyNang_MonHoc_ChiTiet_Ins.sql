CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_ChiTiet_Ins]
    @KyNang_MonHocID INT
  , @TenKyNang       NVARCHAR(200)
  , @MoTaKyNang      NVARCHAR(1000)
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    INSERT INTO tblEL_KyNang_MonHoc_ChiTiet
    (
        KyNang_MonHocID
      , TenKyNang
      , MoTaKyNang
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @KyNang_MonHocID
      , @TenKyNang
      , @MoTaKyNang
      , @SYS_USERID
      , GETDATE()
    );
END;