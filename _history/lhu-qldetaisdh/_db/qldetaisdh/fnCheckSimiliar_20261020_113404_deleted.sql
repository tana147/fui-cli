CREATE FUNCTION fnCheckSimiliar
(
    @ThesisName NVARCHAR(4000)

)
RETURNS NVARCHAR(4000)
BEGIN
	DECLARE @out NVARCHAR(4000)
	SET @out =  STUFF((--SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					SELECT  TOP 10 ', ' + ThesisName
					FROM  [dbo].[Thesises] WHERE ThesisName LIKE N'%' +  @ThesisName +'%'
					 FOR XML PATH('')), 1, 2, '') 
	RETURN @out

END