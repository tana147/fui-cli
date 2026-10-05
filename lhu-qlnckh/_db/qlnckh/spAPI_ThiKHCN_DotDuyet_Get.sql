CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_DotDuyet_Get]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        DotDuyetID,
        TenDotDuyet,
        NienKhoa,
        ThoiGianBatDau,
        ThoiGianKetThuc,
        GhiChu,
        TinhTrang
    FROM ThiKHCN_DotDuyet
    WHERE Is_Xoa = 0
    ORDER BY DotDuyetID DESC;
END;