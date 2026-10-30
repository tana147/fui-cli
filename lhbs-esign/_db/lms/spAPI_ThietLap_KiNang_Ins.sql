CREATE PROC [dbo].[spAPI_ThietLap_KiNang_Ins]
    @NienKhoa    INT
  , @List_NhomID NVARCHAR(1000)
  , @LoaiDiem    NVARCHAR(50)
  , @HocKi       NVARCHAR(50)
  , @TenKiNang   NVARCHAR(50)
  , @MaCotDiem   NVARCHAR(200)
  , @SoCau   INT
  , @SYS_USERID  VARCHAR(9)
AS
BEGIN
    INSERT INTO dbo.tblThietLap_KiNang
    (
        NienKhoa
      , List_NhomID
      , LoaiDiem
      , HocKi
      , TenKiNang
      , MaCotDiem
      , SoCau
      , Enable
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @NienKhoa
      , @List_NhomID
      , @LoaiDiem
      , @HocKi      -- HocKi - nvarchar(50)
      , @TenKiNang  -- KiNang - nchar(10)
      , @MaCotDiem
      , @SoCau  -- SoCauDung - int
      , 1           -- Enable - bit
      , @SYS_USERID -- CreateUser - varchar(50)
      , GETDATE()   -- CreateTime - datetime
    );
END;