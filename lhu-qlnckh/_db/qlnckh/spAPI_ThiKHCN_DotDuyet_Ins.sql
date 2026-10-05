CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_DotDuyet_Ins]
    @TenDotDuyet NVARCHAR(150),
    @NienKhoa VARCHAR(10),
    @ThoiGianBatDau SMALLDATETIME,
    @ThoiGianKetThuc SMALLDATETIME,
    @GhiChu NVARCHAR(500),
    @TinhTrang TINYINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO ThiKHCN_DotDuyet (
        TenDotDuyet,
        NienKhoa,
        ThoiGianBatDau,
        ThoiGianKetThuc,
        GhiChu,
        TinhTrang,
        Is_Xoa,
        CreateTime
    )
    VALUES (
        @TenDotDuyet,
        @NienKhoa,
        @ThoiGianBatDau,
        @ThoiGianKetThuc,
        @GhiChu,
        ISNULL(@TinhTrang, 1),
        0,
        GETDATE()
    );

    SELECT SCOPE_IDENTITY() AS DotDuyetID;
END;
