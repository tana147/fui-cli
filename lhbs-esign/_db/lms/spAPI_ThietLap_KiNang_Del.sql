CREATE PROC [dbo].[spAPI_ThietLap_KiNang_Del]
    @ThietLapID INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblThietLap_KiNang
    SET    Enable = 0
         , UpdateUser = @SYS_USERID
         , UpdateTime = GETDATE()
    WHERE
           ThietLapID = @ThietLapID;
END;