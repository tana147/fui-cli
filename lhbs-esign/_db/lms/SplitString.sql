CREATE FUNCTION [dbo].[SplitString] ( @Input NVARCHAR(MAX), @Delimiter CHAR(1) ) 
RETURNS @Output TABLE (Item NVARCHAR(MAX)) AS 
BEGIN 
DECLARE @Start INT, @End INT 
DECLARE @value NVARCHAR(100);
  
  set @Input = replace(@Input,'(',' ( '); 
  set @Input = replace(@Input,')',' ) ');
  set @Input = replace(@Input,'  ',' ');
  
  SET @Start = 1  
  SET @End = CHARINDEX(@Delimiter, @Input)
	 WHILE @Start < LEN(@Input) + 1 
	 BEGIN 
		IF @End = 0 
			SET @End = LEN(@Input) + 1 
	    set @value = ltrim(rtrim(SUBSTRING(@Input, @Start, @End - @Start)));
		if len(@value)>0
		      INSERT INTO @Output (Item) VALUES(@value) 
		SET @Start = @End + 1 
		SET @End = CHARINDEX(@Delimiter, @Input, @Start) 
	END 
	RETURN 
 END 