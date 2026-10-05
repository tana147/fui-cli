
CREATE FUNCTION [dbo].[Num2Text] (@num INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @word NVARCHAR(50)
    SET @word = ''
IF @num = 1 SET @word = N'một'
ELSE IF @num = 2 SET @word = N'hai'
ELSE IF @num = 3 SET @word = N'ba'
ELSE IF @num = 4 SET @word = N'bốn'
ELSE IF @num = 5 SET @word = N'năm'
ELSE IF @num = 6 SET @word = N'sáu'
ELSE IF @num = 7 SET @word = N'bảy'
ELSE IF @num = 8 SET @word = N'tám'
ELSE IF @num = 9 SET @word = N'chín'
ELSE IF @num = 10 SET @word = N'mười'
ELSE
    BEGIN
        SET @word = 
            CASE 
                WHEN @num BETWEEN 11 AND 19 THEN N'mười ' + CAST([dbo].Num2Text(@num % 10) AS NVARCHAR)
                WHEN @num = 20 THEN N'hai mươi'
                WHEN @num BETWEEN 21 AND 29 THEN N'hai mươi ' + CAST([dbo].Num2Text(@num % 20) AS NVARCHAR)
                WHEN @num = 30 THEN N'ba mươi'
                WHEN @num BETWEEN 31 AND 39 THEN N'ba mươi ' + CAST([dbo].Num2Text(@num % 30) AS NVARCHAR)
                WHEN @num = 40 THEN N'bốn mươi'
                WHEN @num BETWEEN 41 AND 49 THEN 'bốn mươi ' + CAST([dbo].Num2Text(@num % 40) AS NVARCHAR)
                WHEN @num = 50 THEN N'năm mươi'
            END
    END

    RETURN @word
END


