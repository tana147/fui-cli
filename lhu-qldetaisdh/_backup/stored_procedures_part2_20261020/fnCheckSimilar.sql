CREATE FUNCTION [dbo].[fnCheckSimilar]
(
    @TenDeTai NVARCHAR(4000)
)
RETURNS NVARCHAR(4000)
AS
BEGIN
    DECLARE @out NVARCHAR(4000)
    --CREATE TABLE #tbl (ThesisName NVARCHAR(500))

    --INSERT INTO @tbl (ThesisName)
    --SELECT TOP 10 ThesisName
    --FROM [dbo].[Thesises]
    --WHERE ThesisName LIKE N'%' + @TenDeTai + '%'

    --IF (SELECT COUNT(*) FROM @tbl) > 0
    --BEGIN
    --    SELECT ThesisName FROM @tbl
    --END
    --ELSE
    --BEGIN
    --    SELECT TOP 10 ThesisName
    --    FROM [dbo].[Thesises]
    --    WHERE dbo.edit_distance(@TenDeTai, ThesisName) <= 30
    --END

    SET @out = STUFF((
  --      SELECT TOP 10 ', ' + ThesisName
  --      FROM [dbo].[Thesises]
		--	WHERE ThesisName LIKE N'%' + @TenDeTai + '%'
		--UNION 
		 SELECT TOP 10 ThesisName
        FROM [dbo].[Thesises]
        WHERE dbo.edit_distance(@TenDeTai, ThesisName) <= 30
        FOR XML PATH('')
    ), 1, 2, '')

    RETURN @out
END
