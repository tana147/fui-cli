
CREATE FUNCTION [dbo].[FN_STRING_SPLIT]
(
    @String NVARCHAR(4000),
    @Delimiter NCHAR(1)
)
RETURNS TABLE 
AS
RETURN 
(
	WITH Split(stpos,endpos) 
    AS(
        SELECT 0 AS stpos, CHARINDEX(@Delimiter,@String) AS endpos
        UNION ALL
        SELECT endpos+1, CHARINDEX(@Delimiter,@String,endpos+1)
            FROM Split
            WHERE endpos > 0
    )
	SELECT ID = ROW_NUMBER() OVER (ORDER BY (SELECT 1)), Data
	FROM (SELECT Data = RTrim(LTrim(SUBSTRING(@String,stpos,COALESCE(NULLIF(endpos,0),LEN(@String)+1)-stpos))) FROM Split )Tmp
 )