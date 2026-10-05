CREATE PROCEDURE [dbo].[CalculatePayment]
    @FormulaID INT,
    @Score FLOAT,
    @AuthorPosition FLOAT,
    @TotalAuthors INT,
    @ImpactFactor FLOAT,
    @QualityFactor FLOAT
AS
BEGIN
    DECLARE @FormulaExpression NVARCHAR(MAX);
    
    SELECT @FormulaExpression = CongThucKhenThuong
    FROM CongThucKhenThuong
    WHERE CongThucKhenThuongID = @FormulaID;
    
    SET @FormulaExpression = REPLACE(@FormulaExpression, '@Score', CAST(@Score AS NVARCHAR));
    SET @FormulaExpression = REPLACE(@FormulaExpression, '@AuthorPosition', CAST(@AuthorPosition AS NVARCHAR));
    SET @FormulaExpression = REPLACE(@FormulaExpression, '@TotalAuthors', CAST(@TotalAuthors AS NVARCHAR));
    SET @FormulaExpression = REPLACE(@FormulaExpression, '@ImpactFactor', CAST(@ImpactFactor AS NVARCHAR));
    SET @FormulaExpression = REPLACE(@FormulaExpression, '@QualityFactor', CAST(@QualityFactor AS NVARCHAR));
   -- EXEC sp_executesql  @FormulaExpression, N'@Payment FLOAT OUTPUT', @Payment OUTPUT;
	PRINT @FormulaExpression
    EXEC sp_executesql  @FormulaExpression
END;


