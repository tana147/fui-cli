CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Dot_Get]
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        DotID,
        TenDot,
        NamHoc,
        CONVERT(VARCHAR(10), ThoiGianBatDau, 23) AS ThoiGianBatDau,
        CONVERT(VARCHAR(10), ThoiGianKetThuc, 23) AS ThoiGianKetThuc,
        CONVERT(VARCHAR(10), ThoiGianBatDau, 103) AS ThoiGianBatDauFormatted,
        CONVERT(VARCHAR(10), ThoiGianKetThuc, 103) AS ThoiGianKetThucFormatted,
        ThongBao,
        TinhTrang,
        FileHuongDan,
        FileNameHuongDan,
        CASE WHEN GETDATE() BETWEEN ThoiGianBatDau AND ThoiGianKetThuc AND TinhTrang = 1 THEN 1 ELSE 0 END AS IsActive
    FROM ThiKHCN_Dot
    WHERE Is_Xoa = 0
    ORDER BY TinhTrang DESC, DotID DESC;
END;