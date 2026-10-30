CREATE function [dbo].[fn_LoaiBoDau](@st nvarchar(max)) returns varchar(max)
as

	--Set @st = dbo.RegexReplace(@st,N'(?i)[àáạảãâầấậẩẫăằắặẳẵ](?-i)','a')
	--Set @st = dbo.RegexReplace(@st,N'(?i)[èéẹẻẽêềếệểễ](?-i)','e')
	--Set @st = dbo.RegexReplace(@st,N'(?i)[ìíịỉĩ](?-i)','i')
	--Set @st = dbo.RegexReplace(@st,N'(?i)[òóọỏõôồốộổỗơờớợởỡ](?-i)','o')
	--Set @st = dbo.RegexReplace(@st,N'(?i)[ùúụủũưừứựửữ](?-i)','u')
	--Set @st = dbo.RegexReplace(@st,N'(?i)[ỳýỵỷỹ](?-i)','y')
	--Set @st = dbo.RegexReplace(@st,N'[đ]','d')
	--Set @st = dbo.RegexReplace(@st,N'[Đ]','D')

	--return @st;
begin
	DECLARE @accents NVARCHAR(100) = N'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđ'
    DECLARE @noaccents NVARCHAR(100) = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
    DECLARE @i INT = 1

    WHILE @i <= LEN(@accents)
    BEGIN
        SET @st = REPLACE(@st, SUBSTRING(@accents, @i, 1), SUBSTRING(@noaccents, @i, 1))
        SET @i = @i + 1
    END
    
    RETURN @st
end
