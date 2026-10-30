CREATE FUNCTION [dbo].[RenderNhanXet_TinhTrang]
(
    @TinhTrang TINYINT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @TenTinhTrang NVARCHAR(100) = N'';
    IF (@TinhTrang = 0)
        SET @TenTinhTrang = N'Chưa lưu';
    ELSE IF (@TinhTrang = 1)
        SET @TenTinhTrang = N'Lưu tạm';
    ELSE IF (@TinhTrang = 2)
        SET @TenTinhTrang = N'Gửi nhận xét';
    ELSE IF (@TinhTrang = 3)
        SET @TenTinhTrang = N'Từ chối nhận xét';
    ELSE IF (@TinhTrang = 4)
        SET @TenTinhTrang = N'Đã duyệt';
    --ELSE IF (@TinhTrang = 5)
    --    SET @TenTinhTrang = N'Từ chối duyệtnhận xét';
    --ELSE IF (@TinhTrang = 6)
    --    SET @TenTinhTrang = N'Duyệtnhận xét';
    RETURN @TenTinhTrang;
END;
