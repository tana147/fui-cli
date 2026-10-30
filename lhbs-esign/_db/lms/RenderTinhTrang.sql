CREATE FUNCTION [dbo].[RenderTinhTrang]
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
        SET @TenTinhTrang = N'GVBM gửi điểm';
    ELSE IF (@TinhTrang = 3)
        SET @TenTinhTrang = N'GVCN từ chối gửi điểm bộ môn';
    ELSE IF (@TinhTrang = 4)
        SET @TenTinhTrang = N'GVCN gửi điểm';
    ELSE IF (@TinhTrang = 5)
        SET @TenTinhTrang = N'Tổ trưởng từ chối';
    ELSE IF (@TinhTrang = 6)
        SET @TenTinhTrang = N'Tổ trưởng Gửi BGH';
    ELSE IF (@TinhTrang = 7)
        SET @TenTinhTrang = N'BGH từ chối';
    ELSE IF (@TinhTrang = 8)
        SET @TenTinhTrang = N'BGH duyệt (Công bố phụ huynh)';
    RETURN @TenTinhTrang;
END;
