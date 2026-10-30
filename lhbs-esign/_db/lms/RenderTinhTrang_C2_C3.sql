CREATE FUNCTION [dbo].[RenderTinhTrang_C2_C3]
(
    @TinhTrang TINYINT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @TenTinhTrang NVARCHAR(100) = N'';
    IF (@TinhTrang = 0 OR @TinhTrang IS NULL OR @TinhTrang = '')
        SET @TenTinhTrang = N'Chưa lưu';
    ELSE IF (@TinhTrang = 1)
        SET @TenTinhTrang = N'Lưu tạm';
    ELSE IF (@TinhTrang = 2)
        SET @TenTinhTrang = N'Gửi điểm BGH';
    ELSE IF (@TinhTrang = 3)
        SET @TenTinhTrang = N'BGH Từ chối';
    ELSE IF (@TinhTrang = 4)
        SET @TenTinhTrang = N'Duyệt điểm';
    RETURN @TenTinhTrang;
END;
