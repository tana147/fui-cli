
-- Tạo function đơn giản hơn
CREATE FUNCTION [dbo].[fn_EscapeHTMLQuotes](@JSON NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX) = @JSON;
    
    -- Escape các HTML attributes phổ biến
    SET @Result = REPLACE(@Result, 'style="', 'style=\"');
    SET @Result = REPLACE(@Result, 'class="', 'class=\"');
    SET @Result = REPLACE(@Result, 'src="', 'src=\"');
    SET @Result = REPLACE(@Result, 'alt="', 'alt=\"');
    SET @Result = REPLACE(@Result, 'href="', 'href=\"');
    SET @Result = REPLACE(@Result, 'colspan="', 'colspan=\"');
    SET @Result = REPLACE(@Result, 'rowspan="', 'rowspan=\"');
    
    -- Escape đóng attributes
    SET @Result = REPLACE(@Result, '">', '\">');
    SET @Result = REPLACE(@Result, '" >', '\" >');
    SET @Result = REPLACE(@Result, '"/>', '\"/>');
    SET @Result = REPLACE(@Result, '" />', '\" />');
    
    RETURN @Result;
END;

