 CREATE FUNCTION dbo.RemoveDiacritics(@input NVARCHAR(255))
RETURNS NVARCHAR(255)
AS
BEGIN
    DECLARE @output NVARCHAR(255)
    
    -- Thay thế các ký tự có dấu thành không dấu
    SET @output = @input
    SET @output = REPLACE(@output, 'á', 'a')
    SET @output = REPLACE(@output, 'à', 'a')
    SET @output = REPLACE(@output, 'ả', 'a')
    SET @output = REPLACE(@output, 'ã', 'a')
    SET @output = REPLACE(@output, 'ạ', 'a')

    SET @output = REPLACE(@output, 'ă', 'a')
    SET @output = REPLACE(@output, 'ắ', 'a')
    SET @output = REPLACE(@output, 'ằ', 'a')
    SET @output = REPLACE(@output, 'ẳ', 'a')
    SET @output = REPLACE(@output, 'ẵ', 'a')
    SET @output = REPLACE(@output, 'ặ', 'a')

    SET @output = REPLACE(@output, 'â', 'a')
    SET @output = REPLACE(@output, 'ấ', 'a')
    SET @output = REPLACE(@output, 'ầ', 'a')
    SET @output = REPLACE(@output, 'ẩ', 'a')
    SET @output = REPLACE(@output, 'ẫ', 'a')
    SET @output = REPLACE(@output, 'ậ', 'a')

    SET @output = REPLACE(@output, 'é', 'e')
    SET @output = REPLACE(@output, 'è', 'e')
    SET @output = REPLACE(@output, 'ẻ', 'e')
    SET @output = REPLACE(@output, 'ẽ', 'e')
    SET @output = REPLACE(@output, 'ẹ', 'e')

    SET @output = REPLACE(@output, 'ê', 'e')
    SET @output = REPLACE(@output, 'ế', 'e')
    SET @output = REPLACE(@output, 'ề', 'e')
    SET @output = REPLACE(@output, 'ể', 'e')
    SET @output = REPLACE(@output, 'ễ', 'e')
    SET @output = REPLACE(@output, 'ệ', 'e')

    SET @output = REPLACE(@output, 'í', 'i')
    SET @output = REPLACE(@output, 'ì', 'i')
    SET @output = REPLACE(@output, 'ỉ', 'i')
    SET @output = REPLACE(@output, 'ĩ', 'i')
    SET @output = REPLACE(@output, 'ị', 'i')

    SET @output = REPLACE(@output, 'ó', 'o')
    SET @output = REPLACE(@output, 'ò', 'o')
    SET @output = REPLACE(@output, 'ỏ', 'o')
    SET @output = REPLACE(@output, 'õ', 'o')
    SET @output = REPLACE(@output, 'ọ', 'o')

    SET @output = REPLACE(@output, 'ô', 'o')
    SET @output = REPLACE(@output, 'ố', 'o')
    SET @output = REPLACE(@output, 'ồ', 'o')
    SET @output = REPLACE(@output, 'ổ', 'o')
    SET @output = REPLACE(@output, 'ỗ', 'o')
    SET @output = REPLACE(@output, 'ộ', 'o')

    SET @output = REPLACE(@output, 'ơ', 'o')
    SET @output = REPLACE(@output, 'ớ', 'o')
    SET @output = REPLACE(@output, 'ờ', 'o')
    SET @output = REPLACE(@output, 'ở', 'o')
    SET @output = REPLACE(@output, 'ỡ', 'o')
    SET @output = REPLACE(@output, 'ợ', 'o')

    SET @output = REPLACE(@output, 'ú', 'u')
    SET @output = REPLACE(@output, 'ù', 'u')
    SET @output = REPLACE(@output, 'ủ', 'u')
    SET @output = REPLACE(@output, 'ũ', 'u')
    SET @output = REPLACE(@output, 'ụ', 'u')

    SET @output = REPLACE(@output, 'ư', 'u')
    SET @output = REPLACE(@output, 'ứ', 'u')
    SET @output = REPLACE(@output, 'ừ', 'u')
    SET @output = REPLACE(@output, 'ử', 'u')
    SET @output = REPLACE(@output, 'ữ', 'u')
    SET @output = REPLACE(@output, 'ự', 'u')

    SET @output = REPLACE(@output, 'ý', 'y')
    SET @output = REPLACE(@output, 'ỳ', 'y')
    SET @output = REPLACE(@output, 'ỷ', 'y')
    SET @output = REPLACE(@output, 'ỹ', 'y')
    SET @output = REPLACE(@output, 'ỵ', 'y')

    RETURN @output
END;
