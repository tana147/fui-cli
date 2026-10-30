CREATE PROCEDURE [dbo].[spAPI_FP_AI_WordToQuizJSON_Extract_FromHTML]
    @HtmlContent NVARCHAR(MAX),         -- ✅ Nội dung đề thi từ CKEditor
    @TieuDe NVARCHAR(500) = N'Bài kiểm tra trắc nghiệm',
    @ThoiGianLam INT = 30,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClaudeApiKey NVARCHAR(500);
    SELECT @ClaudeApiKey = ConfigValue 
    FROM tblSystemConfig 
    WHERE ConfigKey = 'LMS_Quiz_Extraction';

    IF @ClaudeApiKey IS NULL OR @ClaudeApiKey = ''
    BEGIN
        SELECT success = 0, message = N'Chưa cấu hình Claude API Key', quiz_json = NULL;
        RETURN;
    END

        DECLARE @Prompt NVARCHAR(MAX) = N'
Tôi có một đề thi trắc nghiệm dưới dạng HTML (sao chép từ file Word). Hãy phân tích và trích xuất TẤT CẢ câu hỏi theo format sau:

1. Mỗi câu hỏi bắt đầu bằng "<strong>Câu X.</strong>" hoặc "Câu X."
2. Có 4 đáp án A, B, C, D (nằm trong các thẻ <li>, <p>, hoặc <ul>)
3. Đáp án đúng được đánh dấu bằng:
   - Gạch chân bằng thẻ <u>...</u>
   - Hoặc được in đậm bằng <strong>...</strong>
  

YÊU CẦU:
### 1. Format bắt buộc cho mỗi câu hỏi:
{
  "id": "q1",
  "type": "QUIZ_SINGLE_CHOICE",
  "points": 1,
  "content": {
    "prompt": "<p><strong>Câu 1.</strong> [Nội dung câu hỏi]</p>",
    "options": [
      { "id": "a", "text": "[Đáp án A]" },
      { "id": "b", "text": "[Đáp án B]" },
      { "id": "c", "text": "[Đáp án C]" },
      { "id": "d", "text": "[Đáp án D]" }
    ],
    "correctAnswer": "[a/b/c/d]"
  }
}
### 2.  - Loại bỏ các dấu hiệu đậm, gạch chân, nghiêng ra khỏi đáp án đúng ra khỏi đáp án đúng

- **Tuyệt đối không trả về dạng "options": ["A. ...", "B. ..."]**
- **Trả về TRỰC TIẾP JSON**, không chú thích, không markdown
-- Đây là data mẫu của 1 bài để tham khảo, không đưa nó thành nội dung output
{"questions":[{"id":"q_1751039509305","type":"QUIZ_SINGLE_CHOICE","points":1,"content":{"prompt":"Tác phẩm dế Mèn Phiêu Lưu Kí của ai?","options":[{"id":"a","text":"Tô Hoài"},{"id":"b","text":"Tô Tượng"},{"id":"c","text":"Vẽ Hoài"},{"id":"d","text":"Tô Châu"}],"correctAnswer":"a"}},{"id":"q_1751039592921","type":"QUIZ_MULTIPLE_CHOICE","points":1,"content":{"prompt":"Dế mèn là người như thế nào","options":[{"id":"a","text":"Khoẻ mạnh"},{"id":"b","text":"Thông minh"},{"id":"c","text":"Hài hước"},{"id":"d","text":"Thích khám phá"}],"correctAnswers":["a","d"]}},{"id":"q_1751039646757","type":"QUIZ_FILL_IN_BLANK","points":1,"content":{"prompt":"Điền từ còn trống","parts":[{"type":"text","value":"Dế"},{"type":"blank","id":"blank_1751039671786","correctAnswer":"mèn","size":10},{"type":"text","value":"phiêu"},{"type":"blank","id":"blank_1751039678914","correctAnswer":"lưu","size":10},{"type":"text","value":"ký"}]}}],"title":"Bài kiểm tra số 1","timeLimit":1800,"totalPoints":10,"passingScore":5}

Dưới đây là nội dung đề thi dạng HTML:
' + @HtmlContent;


    -- Request
    DECLARE @ClaudeRequest NVARCHAR(MAX) = CONCAT(
        '{',
        '"model": "claude-3-haiku-20240307",',
        '"max_tokens": 2048,',
        '"temperature": 0,',
        '"messages": [{',
            '"role": "user",',
            '"content": ', dbo.JSON_Stringify(@Prompt),
        '}]',
        '}'
    );

    -- Headers (dùng | làm phân tách nếu dùng httpAPI tùy chỉnh)
    DECLARE @Headers NVARCHAR(500) = CONCAT(
        'x-api-key: ', @ClaudeApiKey, '|',
        'anthropic-version: 2023-06-01'
    );

    DECLARE @AIResponse NVARCHAR(MAX) = '';
    DECLARE @QuizJSON NVARCHAR(MAX) = NULL;
    DECLARE @Success BIT = 0;
    DECLARE @Message NVARCHAR(500) = '';
    DECLARE @ProcessingLog NVARCHAR(MAX) = '';

    BEGIN TRY
        SET @AIResponse = dbo.httpAPI(
            'POST', 
            'https://api.anthropic.com/v1/messages', 
            @Headers, 
            @ClaudeRequest
        );

        SET @ProcessingLog = CONCAT(
            '[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Claude response received.', CHAR(13), CHAR(10)
        );

        -- Extract nội dung JSON
        IF @AIResponse LIKE '%"content":%' AND @AIResponse LIKE '%"text":%'
        BEGIN
            DECLARE @StartPos INT = CHARINDEX('"text":"', @AIResponse) + 8;
            DECLARE @EndPos INT = CHARINDEX('"}]', @AIResponse, @StartPos);

            IF @StartPos > 8 AND @EndPos > @StartPos
            BEGIN
                SET @QuizJSON = SUBSTRING(@AIResponse, @StartPos, @EndPos - @StartPos);
                -- Làm sạch escape JSON
				SET @QuizJSON = REPLACE(@QuizJSON, '\n', '');
				SET @QuizJSON = REPLACE(@QuizJSON, '\\n', '');
				SET @QuizJSON = REPLACE(@QuizJSON, '\\r', '');
				SET @QuizJSON = REPLACE(@QuizJSON, '\\t', '');
				SET @QuizJSON = REPLACE(@QuizJSON, '\\\"', '\"');
				SET @QuizJSON = REPLACE(@QuizJSON, '\\\\', '');
				SET @QuizJSON = REPLACE(@QuizJSON, '\"', '"');

				-- Làm sạch xuống dòng thật
				SET @QuizJSON = REPLACE(@QuizJSON, CHAR(10), '');
				SET @QuizJSON = REPLACE(@QuizJSON, CHAR(13), '');


                IF ISJSON(@QuizJSON) = 1
                BEGIN
                    SET @Success = 1;
                    SET @Message = N'Trích xuất thành công từ Claude AI';
                END
                ELSE
                BEGIN
                    SET @Message = N'Dữ liệu JSON trả về không hợp lệ';
                END
            END
        END
        ELSE
        BEGIN
            SET @Message = LEFT(@AIResponse, 300);
        END
    END TRY
    BEGIN CATCH
        SET @Message = ERROR_MESSAGE();
        SET @Success = 0;
        SET @ProcessingLog = CONCAT(@ProcessingLog, '[ERROR] ', @Message);
    END CATCH

    -- Return
    SELECT 
        success = @Success,
        message = @Message,
        quiz_json = @QuizJSON,
        processing_log = @ProcessingLog;
END
