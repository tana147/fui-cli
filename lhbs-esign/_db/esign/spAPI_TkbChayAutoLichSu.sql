CREATE PROCEDURE spAPI_TkbChayAutoLichSu
    @Top INT = 20,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP (@Top)
        RunID, ThoiGianBatDau, ThoiGianKetThuc, Khoi, MaxSecs, TrangThai, KhaThi,
        SoNhuCau, SoSlotDaXep, TietTrongLe, SoGvKhongCoBuoiRanh, SoLuotVuotTranTietNgay,
        SoTietViPhamChaoCo, SoLuotLechTrack, SoTietShKhongKem, NguoiChay
    FROM tblTKB_ChayAutoLog
    WHERE Enable = 1
    ORDER BY RunID DESC;
END