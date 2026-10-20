CREATE PROC [dbo].[spAPI_Get_SimiliarPaper] -- N'Hoàn thiện hệ thống kiểm soát nội bộ tại Công ty TNHH PT Việt'
 @TenDeTai AS NVARCHAR(500)
 AS
 BEGIN

	DECLARE @tbl AS TABLE (ThesisName NVARCHAR(500), ThesisStudent NVARCHAR(500), ThesisMajor NVARCHAR(500))
	INSERT INTO @tbl(ThesisName, ThesisStudent, ThesisMajor)
	SELECT  TOP 10 ThesisName, ThesisStudent, ThesisMajor
		FROM  [dbo].[Thesises] WHERE ThesisName LIKE N'%' +  @TenDeTai +'%'
	IF (SELECT COUNT(*) FROM @tbl) >0
	BEGIN
		SELECT  ThesisName, ThesisStudent, ThesisMajor
		FROM  @tbl
	END
	ELSE
	BEGIN
		PRINT 'X'
		SELECT TOP 5 ThesisName, ThesisStudent, ThesisMajor
		FROM  [dbo].[Thesises]
		WHERE dbo.edit_distance(@TenDeTai, ThesisName) <=30
	END
	
		

	--SELECT TOP 5 ThesisName, ThesisStudent, ThesisMajor
	--FROM  [dbo].[Thesises]
	--WHERE dbo.edit_distance(@TenDeTai, ThesisName) <=30
	
	--IF @@ROWCOUNT = 0
	--BEGIN
		
	--END

 END