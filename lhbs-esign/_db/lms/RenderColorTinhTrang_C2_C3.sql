CREATE FUNCTION [dbo].[RenderColorTinhTrang_C2_C3]
(
    @TinhTrang TINYINT
)
RETURNS NVARCHAR(100)
AS
BEGIN
    DECLARE @MauTinhTrang NVARCHAR(100) = N'';
    IF (
           @TinhTrang = 0
      OR   @TinhTrang IS NULL
      OR   @TinhTrang = ''
       )
        SET @MauTinhTrang = N'blue-grey'; -- Chưa lưu
    ELSE IF (@TinhTrang = 1)
        SET @MauTinhTrang = N'light-green-lighten-1'; -- Lưu tạm
    ELSE IF (@TinhTrang = 2)
        SET @MauTinhTrang = N'primary'; -- Gửi điểm BGH
    ELSE IF (@TinhTrang = 3)
        SET @MauTinhTrang = N'error'; -- GVCN từ chối, Tổ trưởng từ chối, BGH từ chối
    ELSE IF (@TinhTrang = 4)
        SET @MauTinhTrang = N'success'; -- GVCN gửi điểm, Tổ trưởng Gửi BGH
    RETURN @MauTinhTrang;
END;
