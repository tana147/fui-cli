

CREATE FUNCTION dbo.BuildFormula (@FormulaID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @BaseFormula NVARCHAR(MAX);
    DECLARE @DynamicColumns NVARCHAR(MAX);

    -- Lấy công thức cơ bản
    SELECT @BaseFormula = BaseFormula
    FROM FormulaConfig
    WHERE FormulaID = @FormulaID;

    -- Tạo cột động từ bảng ánh xạ
    SELECT @DynamicColumns = STUFF((
        SELECT ' + ' + 
            CASE 
                WHEN Condition IS NOT NULL THEN 
                    'CASE WHEN ' + Condition + ' THEN ' + ColumnName + ' ELSE 0 END * ' + CAST(Weight AS NVARCHAR)
                ELSE ColumnName + ' * ' + CAST(Weight AS NVARCHAR)
            END
        FROM FormulaColumns
        WHERE FormulaID = @FormulaID
        FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 3, '');

    -- Thay thế cột động vào công thức
    SET @BaseFormula = REPLACE(@BaseFormula, '<DynamicColumns>', @DynamicColumns);

    RETURN @BaseFormula;
END;


