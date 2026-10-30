CREATE FUNCTION [dbo].[RenderNhanXet_ColorTinhTrang]
(
    @TinhTrang TINYINT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @MauTinhTrang NVARCHAR(100) = N'';
    IF (@TinhTrang = 0)
        SET @MauTinhTrang = N'default'; -- Chưa lưu
    ELSE IF (@TinhTrang = 1)
        SET @MauTinhTrang = N'primary'; -- Lưu tạm
    ELSE IF (@TinhTrang = 2)
        SET @MauTinhTrang = N'warning'; -- GVBM gửi điểm
    ELSE IF (
                @TinhTrang = 3
           OR   @TinhTrang = 5
           OR   @TinhTrang = 7
            )
        SET @MauTinhTrang = N'error'; -- GVCN từ chối, Tổ trưởng từ chối, BGH từ chối
    ELSE IF (
                @TinhTrang = 4
           OR   @TinhTrang = 6
            )
        SET @MauTinhTrang = N'success'; -- GVCN gửi điểm, Tổ trưởng Gửi BGH
   
    RETURN @MauTinhTrang;
END;
