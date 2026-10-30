CREATE PROCEDURE spAPI_TkbCumTachChiTiet
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT ID, MaCumTach, Khoi, TenCum, GhiChu, Enable FROM tblTKB_CumTach WHERE ID = @ID;
    SELECT MaLop FROM tblTKB_CumTach_LopNguon WHERE CumTachID = @ID ORDER BY MaLop;
    SELECT MaLop FROM tblTKB_CumTach_NhomCon WHERE CumTachID = @ID ORDER BY MaLop;
END
