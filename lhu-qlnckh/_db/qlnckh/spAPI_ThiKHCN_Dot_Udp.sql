CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Dot_Udp]
    @DotID INT,
    @TenDot NVARCHAR(250),
    @NamHoc VARCHAR(20),
    @ThoiGianBatDau DATE,
    @ThoiGianKetThuc DATE,
    @ThongBao NVARCHAR(MAX),
    @FileHuongDan VARCHAR(50),
    @FileNameHuongDan NVARCHAR(250),
    @TinhTrang TINYINT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu mở đợt này, tự động đóng các đợt khác để chỉ có 1 đợt hiện hành
    IF @TinhTrang = 1
    BEGIN
        UPDATE ThiKHCN_Dot SET TinhTrang = 0 WHERE DotID <> @DotID;
    END;

    UPDATE ThiKHCN_Dot
    SET TenDot = @TenDot,
        NamHoc = @NamHoc,
        ThoiGianBatDau = @ThoiGianBatDau,
        ThoiGianKetThuc = @ThoiGianKetThuc,
        ThongBao = @ThongBao,
        FileHuongDan = @FileHuongDan,
        FileNameHuongDan = @FileNameHuongDan,
        TinhTrang = @TinhTrang
    WHERE DotID = @DotID AND Is_Xoa = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
