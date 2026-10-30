CREATE PROCEDURE [dbo].[sp_GenerateJsonResult]
	@IsSuccess BIT,
	@Message NVARCHAR(4000) NULL,
    @JsonData NVARCHAR(MAX)
AS
BEGIN
	--Nếu ko có data thì gắn bằng string null
	IF(@JsonData IS NULL) 
	BEGIN
	    SET @JsonData = 'null'
	END

    SELECT 
        convert_to_object = '',
        @IsSuccess AS IsSuccess,
        @Message AS [Message],
       '{"Result": ' + @JsonData + '}' AS json_data 
END;