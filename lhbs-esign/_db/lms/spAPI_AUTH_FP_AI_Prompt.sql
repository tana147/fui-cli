CREATE PROCEDURE [dbo].[spAPI_AUTH_FP_AI_Prompt]
    @Prompt NVARCHAR(MAX)
AS
BEGIN
    
	DECLARE @Model NVARCHAR(100) = 'claude-3-haiku-20240307'
    DECLARE @MaxTokens INT = 4096
    DECLARE @Temperature DECIMAL(3,2) = 0
    DECLARE @sys_UserID VARCHAR(50) =''

    -- Lấy Claude API Key từ config
    DECLARE @ClaudeApiKey NVARCHAR(500);
    SELECT @ClaudeApiKey = ConfigValue 
    FROM tblSystemConfig 
    WHERE ConfigKey = 'LMS_Quiz_Extraction';

    -- Kiểm tra API Key
    IF @ClaudeApiKey IS NULL OR @ClaudeApiKey = ''
    BEGIN
        SELECT 
            success = 0, 
            message = N'Chưa cấu hình Claude API Key',
            response_text = NULL,
            full_response = NULL;
        RETURN;
    END;

    -- Tạo request JSON cho Claude API
    DECLARE @ClaudeRequest NVARCHAR(MAX) = CONCAT(
        '{',
        '"model": "', @Model, '",',
        '"max_tokens": ', @MaxTokens, ',',
        '"temperature": ', @Temperature, ',',
        '"messages": [{',
            '"role": "user",',
            '"content": ', dbo.JSON_Stringify(@Prompt),
        '}]',
        '}'
    );

    -- Tạo headers
    DECLARE @Headers NVARCHAR(500) = CONCAT(
        'x-api-key: ', @ClaudeApiKey, '|',
        'anthropic-version: 2023-06-01'
    );

    -- Khởi tạo các biến kết quả
    DECLARE @AIResponse NVARCHAR(MAX) = '';
    DECLARE @ResponseText NVARCHAR(MAX) = NULL;
    DECLARE @Success BIT = 0;
    DECLARE @Message NVARCHAR(500) = '';
    DECLARE @ProcessingLog NVARCHAR(MAX) = '';

    BEGIN TRY
        -- Gọi Claude API
        SET @AIResponse = dbo.httpAPI(
            'POST',
            'https://api.anthropic.com/v1/messages',
            @Headers,
            @ClaudeRequest
        );

        SET @ProcessingLog = CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Claude API response received.', CHAR(13) + CHAR(10));

        -- Kiểm tra và trích xuất response
        IF @AIResponse LIKE '%"content":%' AND @AIResponse LIKE '%"text":%'
        BEGIN
            DECLARE @StartPos INT = CHARINDEX('"text":"', @AIResponse) + 8;
            DECLARE @EndPos INT = CHARINDEX('"}]', @AIResponse, @StartPos);

            IF @StartPos > 8 AND @EndPos > @StartPos
            BEGIN
                SET @ResponseText = SUBSTRING(@AIResponse, @StartPos, @EndPos - @StartPos);

                -- Làm sạch escape JSON
				SET @ResponseText = REPLACE(@ResponseText, '\n', '');
				SET @ResponseText = REPLACE(@ResponseText, '\\n', '');
				SET @ResponseText = REPLACE(@ResponseText, '\\r', '');
				SET @ResponseText = REPLACE(@ResponseText, '\\t', '');
				SET @ResponseText = REPLACE(@ResponseText, '\\\"', '\"');
				SET @ResponseText = REPLACE(@ResponseText, '\\\\', '');
				SET @ResponseText = REPLACE(@ResponseText, '\"', '"');

				-- Làm sạch xuống dòng thật
				SET @ResponseText = REPLACE(@ResponseText, CHAR(10), '');
				SET @ResponseText = REPLACE(@ResponseText, CHAR(13), '');

                SET @Success = 1;
                SET @Message = N'Gọi Claude API thành công';
                SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Response extracted successfully.', CHAR(13) + CHAR(10));
            END
            ELSE
            BEGIN
                SET @Message = N'Không tìm thấy text trong response';
                SET @ProcessingLog += '[ERROR] Could not extract text from response.';
            END
        END
        ELSE
        BEGIN
            SET @Message = N'Response không đúng định dạng: ' + LEFT(@AIResponse, 200);
            SET @ProcessingLog += '[ERROR] Invalid response format.';
        END

    END TRY
    BEGIN CATCH
        SET @Message = ERROR_MESSAGE();
        SET @Success = 0;
        SET @ProcessingLog += '[ERROR] ' + @Message;
    END CATCH

    -- Trả về kết quả
    SELECT 
        success = @Success,
        message = @Message,
        response_text = @ResponseText,
        full_response = @AIResponse,
        processing_log = @ProcessingLog,
        request_info = CONCAT('Model: ', @Model, ', MaxTokens: ', @MaxTokens, ', Temperature: ', @Temperature);
END;