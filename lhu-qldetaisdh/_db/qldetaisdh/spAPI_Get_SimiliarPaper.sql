CREATE PROC [dbo].[spAPI_Get_SimiliarPaper]
@TenDeTai AS NVARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;

	SET @TenDeTai = LTRIM(RTRIM(@TenDeTai));
	IF @TenDeTai IS NULL OR @TenDeTai = N''
		RETURN;

	-- 1. Tìm trực tiếp nếu tên đề tài có chứa @TenDeTai
	IF EXISTS (
		SELECT 1
		FROM [dbo].[Thesises]
		WHERE ThesisName LIKE N'%' + @TenDeTai + '%'
	)
	BEGIN
		SELECT TOP 10 ThesisName, ThesisStudent, ThesisMajor
		FROM [dbo].[Thesises]
		WHERE ThesisName LIKE N'%' + @TenDeTai + '%';
		RETURN;
	END

	-- 2. Nếu không tìm thấy bằng LIKE, tìm theo edit_distance <= 30
	-- Toán học: edit_distance(A, B) luôn >= |len(A) - len(B)|
	-- Lọc trước những đề tài có chênh lệch độ dài <= 30 để tránh chạy scalar UDF trên toàn bộ bảng
	DECLARE @len INT = LEN(@TenDeTai);

	SELECT TOP 5 ThesisName, ThesisStudent, ThesisMajor
	FROM [dbo].[Thesises]
	WHERE ABS(LEN(ThesisName) - @len) <= 30
	  AND dbo.edit_distance(@TenDeTai, ThesisName) <= 30;
END


