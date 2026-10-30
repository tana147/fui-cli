CREATE FUNCTION [dbo].[fn_Calc_WidthColumn](@Content NVARCHAR(1000))
RETURNs int AS  
BEGIN 
	
	DECLARE @Width INT = 40
	SET @Width = (LEN(@Content) * 12)

	return  @Width
END 