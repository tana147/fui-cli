CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_Ins]
    @MonHocID   INT
  , @NhomKyNang NVARCHAR(200)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    INSERT INTO tblEL_KyNang_MonHoc
    (
        MonHocID
      , NhomKyNang
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @MonHocID
      , @NhomKyNang
      , @SYS_USERID
      , GETDATE()
    );
END;