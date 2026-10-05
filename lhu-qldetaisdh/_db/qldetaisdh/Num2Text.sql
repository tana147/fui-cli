CREATE FUNCTION dbo.Num2Text (@num INT)
RETURNS NVARCHAR(100)
WITH INLINE = OFF
AS
BEGIN
    DECLARE @word NVARCHAR(100) = ''
    IF @num IS NULL OR @num <= 0 RETURN ''
    
    DECLARE @tram INT = @num / 100
    DECLARE @chuc INT = (@num % 100) / 10
    DECLARE @dv INT = @num % 10

    IF @tram > 0
        SET @word = CHOOSE(@tram, N'một', N'hai', N'ba', N'bốn', N'năm', N'sáu', N'bảy', N'tám', N'chín') + N' trăm'

    IF @chuc = 0 AND @tram > 0 AND @dv > 0
        SET @word = @word + N' lẻ'
    ELSE IF @chuc = 1
        SET @word = LTRIM(@word + N' mười')
    ELSE IF @chuc > 1
        SET @word = LTRIM(@word + N' ' + CHOOSE(@chuc, N'một', N'hai', N'ba', N'bốn', N'năm', N'sáu', N'bảy', N'tám', N'chín') + N' mươi')

    IF @dv = 1 AND @chuc > 1
        SET @word = @word + N' mốt'
    ELSE IF @dv = 5 AND @chuc >= 1
        SET @word = @word + N' lăm'
    ELSE IF @dv > 0
        SET @word = LTRIM(@word + N' ' + CHOOSE(@dv, N'một', N'hai', N'ba', N'bốn', N'năm', N'sáu', N'bảy', N'tám', N'chín'))

    RETURN LTRIM(RTRIM(@word))
END


