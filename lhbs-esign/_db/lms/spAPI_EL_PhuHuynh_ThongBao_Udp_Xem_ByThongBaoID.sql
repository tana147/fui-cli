CREATE PROC [dbo].[spAPI_EL_PhuHuynh_ThongBao_Udp_Xem_ByThongBaoID]
    @ThongBaoID INT
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @CurrentXem BIT = 0;
    SELECT @CurrentXem = ISNULL(Is_DaXem , 0)
    FROM
           dbo.tblEL_ThongBao
    WHERE
           ThongBaoID = @ThongBaoID;

    IF (@CurrentXem = 0)
    BEGIN
        UPDATE tblEL_ThongBao
        SET    Is_DaXem = 1
             , NguoiXem = @SYS_USERID
             , ThoiGianXem = GETDATE()
        WHERE
               ThongBaoID = @ThongBaoID;
    END;
END;