CREATE PROC [dbo].[spAPI_ThietLap_KiNang_Upd]
    @ThietLapID  INT
  , @List_NhomID NVARCHAR(1000)
  , @TenKiNang   NVARCHAR(50)
  , @SoCau       INT
  , @SYS_USERID  VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblThietLap_KiNang
    SET    List_NhomID = @List_NhomID
         , TenKiNang = @TenKiNang
         , SoCau = @SoCau
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           ThietLapID = @ThietLapID;
END;