CREATE FUNCTION [dbo].[JSON_Stringify] (@Input NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX)
    
    -- Xử lý NULL
    IF @Input IS NULL
        RETURN 'null'
    
    -- Kiểm tra xem đầu vào có phải là JSON hợp lệ không
    IF ISJSON(@Input) = 1
    BEGIN
        DECLARE @IsArray BIT = CASE WHEN LEFT(@Input, 1) = '[' THEN 1 ELSE 0 END
        
        IF @IsArray = 1
        BEGIN
            -- Xử lý mảng JSON
            SET @Result = '['
            DECLARE @Index INT = 1
            DECLARE @Value NVARCHAR(MAX)
            DECLARE @RowCount INT = (SELECT COUNT(*) FROM OPENJSON(@Input))
            
            WHILE @Index <= @RowCount
            BEGIN
                SET @Value = (SELECT value FROM OPENJSON(@Input) WHERE [key] = CAST(@Index-1 AS NVARCHAR(10)))
                SET @Result = @Result + dbo.JSON_Stringify(@Value)
                IF @Index < @RowCount
                    SET @Result = @Result + ','
                SET @Index = @Index + 1
            END
            SET @Result = @Result + ']'
            RETURN @Result
        END
        ELSE
        BEGIN
            -- Xử lý đối tượng JSON
            SET @Result = '{'
            DECLARE @Key NVARCHAR(128)
            DECLARE @JsonValue NVARCHAR(MAX)
            DECLARE @Counter INT = 1
            DECLARE @TotalKeys INT = (SELECT COUNT(*) FROM OPENJSON(@Input))
            
            DECLARE json_cursor CURSOR FOR 
            SELECT [key], value FROM OPENJSON(@Input)
            
            OPEN json_cursor
            FETCH NEXT FROM json_cursor INTO @Key, @JsonValue
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @Result = @Result + '"' + @Key + '":' + dbo.JSON_Stringify(@JsonValue)
                IF @Counter < @TotalKeys
                    SET @Result = @Result + ','
                SET @Counter = @Counter + 1
                FETCH NEXT FROM json_cursor INTO @Key, @JsonValue
            END
            
            CLOSE json_cursor
            DEALLOCATE json_cursor
            
            SET @Result = @Result + '}'
            RETURN @Result
        END
    END
    
    -- Xử lý chuỗi không phải JSON
    DECLARE @StringValue NVARCHAR(MAX) = @Input
    -- Escape các ký tự đặc biệt
    SET @StringValue = REPLACE(@StringValue, '\', '\\')
    SET @StringValue = REPLACE(@StringValue, '"', '\"')
    SET @StringValue = REPLACE(@StringValue, CHAR(10), '\n')
    SET @StringValue = REPLACE(@StringValue, CHAR(13), '\r')
    SET @StringValue = REPLACE(@StringValue, CHAR(9), '\t')
    RETURN '"' + @StringValue + '"'
END