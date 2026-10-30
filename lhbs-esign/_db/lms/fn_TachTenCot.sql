CREATE FUNCTION dbo.fn_TachTenCot(@Formula NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @CleanFormula NVARCHAR(MAX)
    DECLARE @ColumnList NVARCHAR(MAX)

    -- Loại bỏ các ký tự không liên quan như dấu phép toán, dấu ngoặc, số
    SET @CleanFormula = REPLACE(@Formula, '(', ' ')
    SET @CleanFormula = REPLACE(@CleanFormula, ')', ' ')
    SET @CleanFormula = REPLACE(@CleanFormula, '+', ' ')
    SET @CleanFormula = REPLACE(@CleanFormula, '*', ' ')
    SET @CleanFormula = REPLACE(@CleanFormula, '/', ' ')
    
    
    
    -- Loại bỏ các dấu nháy kép trong công thức (trong IF)
    SET @CleanFormula = REPLACE(@CleanFormula, '"', ' ');

    -- Chuyển tất cả thành các tên cột trong công thức
    SET @ColumnList = @CleanFormula;

    -- Xóa tất cả khoảng trắng thừa giữa các từ
    SET @ColumnList = REPLACE(@ColumnList, '  ', ' ');

    -- Tách các tên cột, loại bỏ các từ không phải tên cột
    -- Sử dụng FOR XML PATH để nối các tên cột thành một chuỗi
    DECLARE @Result NVARCHAR(MAX);

    SELECT @Result = COALESCE(@Result + ', ', '') + value
    FROM STRING_SPLIT(@ColumnList, ' ')
    WHERE value LIKE '%_HK1' OR value LIKE '%_HK2';

    RETURN @Result;
END;
