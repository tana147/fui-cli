CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_DotDuyet_Udp]
    @DotDuyetID INT,
    @TenDotDuyet NVARCHAR(150),
    @NienKhoa VARCHAR(10),
    @ThoiGianBatDau SMALLDATETIME,
    @ThoiGianKetThuc SMALLDATETIME,
    @GhiChu NVARCHAR(500),
    @TinhTrang TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ThiKHCN_DotDuyet
    SET TenDotDuyet = @TenDotDuyet,
        NienKhoa = @NienKhoa,
        ThoiGianBatDau = @ThoiGianBatDau,
        ThoiGianKetThuc = @ThoiGianKetThuc,
        GhiChu = @GhiChu,
        TinhTrang = ISNULL(@TinhTrang, 1)
    WHERE DotDuyetID = @DotDuyetID
      AND Is_Xoa = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
