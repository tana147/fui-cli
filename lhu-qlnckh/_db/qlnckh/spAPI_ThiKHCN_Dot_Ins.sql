CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Dot_Ins]
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

    -- Nếu mở đợt mới, tự động đóng các đợt khác để chỉ có 1 đợt hiện hành
    IF @TinhTrang = 1
    BEGIN
        UPDATE ThiKHCN_Dot SET TinhTrang = 0 WHERE TinhTrang = 1;
    END;

    INSERT INTO ThiKHCN_Dot (
        TenDot,
        NamHoc,
        ThoiGianBatDau,
        ThoiGianKetThuc,
        ThongBao,
        FileHuongDan,
        FileNameHuongDan,
        TinhTrang,
        CreateUser,
        CreateTime,
        Is_Xoa
    )
    VALUES (
        @TenDot,
        @NamHoc,
        @ThoiGianBatDau,
        @ThoiGianKetThuc,
        @ThongBao,
        @FileHuongDan,
        @FileNameHuongDan,
        @TinhTrang,
        @SYS_UserID,
        GETDATE(),
        0
    );

    SELECT SCOPE_IDENTITY() AS DotID;
END;
