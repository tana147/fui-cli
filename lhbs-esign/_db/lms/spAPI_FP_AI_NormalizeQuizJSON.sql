CREATE PROCEDURE [dbo].[spAPI_FP_AI_NormalizeQuizJSON]
    @InputJSON NVARCHAR(MAX),
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
        SELECT success = 0, message = N'Chưa cấu hình Claude API Key', normalized_json = NULL;
        RETURN;
    END;

    DECLARE @Prompt NVARCHAR(MAX) = N'
Tôi có một chuỗi JSON quiz bị lỗi format hoặc cần chuẩn hóa. Hãy phân tích và TRẢ VỀ DUY NHẤT MỘT CHUỖI JSON hợp lệ đã được chuẩn hóa theo định dạng sau (KHÔNG GIẢI THÍCH, KHÔNG THÊM CHỮ DẪN).

## ✅ CẤU TRÚC JSON CHUẨN:

{
  "title": "Bài kiểm tra trắc nghiệm",
  "timeLimit": 1800,
  "totalPoints": 0,
  "passingScore": 0,
  "questions": [
    {
      "id": "q1",
      "type": "QUIZ_SINGLE_CHOICE",
      "points": 1,
      "content": {
        "prompt": "<p><strong>Câu 1.</strong> Nội dung câu hỏi</p>",
        "options": [
          { "id": "a", "text": "Đáp án A" },
          { "id": "b", "text": "Đáp án B" },
          { "id": "c", "text": "Đáp án C" },
          { "id": "d", "text": "Đáp án D" }
        ],
        "correctAnswer": "b"
      }
    }
  ]
}

## ✅ QUY TẮC CHUẨN HÓA:

1. **Sửa lỗi JSON syntax**: Dấu ngoặc, dấu phẩy, escape characters
2. **Chuẩn hóa structure**: Đảm bảo đúng cấu trúc như mẫu
3. **Làm sạch content**: 
   - Loại bỏ các thẻ `<strong>`, `<u>` khỏi text đáp án
   - Giữ nguyên HTML trong prompt
   - Escape đúng dấu ngoặc kép trong nội dung
4. **Validate fields**:
   - `id`: "q1", "q2", "q3"...
   - `type`: "QUIZ_SINGLE_CHOICE", "QUIZ_MULTIPLE_CHOICE", "QUIZ_FILL_IN_BLANK", "QUIZ_GROUP"
   - `points`: số nguyên
   - `options[].id`: "a", "b", "c", "d"
   - `correctAnswer`: một trong "a", "b", "c", "d"
   - `correctAnswers`: mảng như ["a", "c"] cho multiple choice
5. **Tính toán totalPoints**: Tổng points của tất cả câu hỏi
6. **Đảm bảo encoding**: UTF-8 cho tiếng Việt

## ❌ LỖI THƯỜNG GẶP CẦN SỬA:
- Dấu ngoặc kép không escape: `"Câu hỏi "abc" def"` → `"Câu hỏi \"abc\" def"`
- Thiếu dấu phẩy giữa các object/array
- Thừa dấu phẩy cuối mảng/object
- Sai cấu trúc nested object
- Sai data type (string thành number hoặc ngược lại)

---

JSON cần chuẩn hóa:
' + @InputJSON;

    DECLARE @ClaudeRequest NVARCHAR(MAX) = CONCAT(
        '{',
        '"model": "claude-3-haiku-20240307",',
        '"max_tokens": 4096,',
        '"temperature": 0,',
        '"messages": [{',
            '"role": "user",',
            '"content": ', dbo.JSON_Stringify(@Prompt),
        '}]',
        '}'
    );

    DECLARE @Headers NVARCHAR(500) = CONCAT(
        'x-api-key: ', @ClaudeApiKey, '|',
        'anthropic-version: 2023-06-01'
    );

    DECLARE @AIResponse NVARCHAR(MAX) = '';
    DECLARE @NormalizedJSON NVARCHAR(MAX) = NULL;
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

        SET @ProcessingLog = CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Claude response received.', CHAR(13) + CHAR(10));

        IF @AIResponse LIKE '%"content":%' AND @AIResponse LIKE '%"text":%'
        BEGIN
            DECLARE @StartPos INT = CHARINDEX('"text":"', @AIResponse) + 8;
            DECLARE @EndPos INT = CHARINDEX('"}]', @AIResponse, @StartPos);

            IF @StartPos > 8 AND @EndPos > @StartPos
            BEGIN
                SET @NormalizedJSON = SUBSTRING(@AIResponse, @StartPos, @EndPos - @StartPos);

                -- Fix escape characters từ Claude response
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\\"', '"');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\\n', '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\\r', '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\\t', '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, CHAR(10), '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, CHAR(13), '');
                
                -- Loại bỏ thêm các escape characters khác
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\n', '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\r', '');
                SET @NormalizedJSON = REPLACE(@NormalizedJSON, '\t', '');
                
                -- Loại bỏ khoảng trắng thừa
                WHILE CHARINDEX('  ', @NormalizedJSON) > 0
                BEGIN
                    SET @NormalizedJSON = REPLACE(@NormalizedJSON, '  ', ' ');
                END

                -- Validate JSON
                IF ISJSON(@NormalizedJSON) = 1
                BEGIN
                    -- Tính toán totalPoints
                    DECLARE @TotalPoints INT = 0;
                    SELECT @TotalPoints = SUM(CAST(JSON_VALUE(value, '$.points') AS INT))
                    FROM OPENJSON(@NormalizedJSON, '$.questions')
                    WHERE JSON_VALUE(value, '$.type') != 'QUIZ_GROUP';

                    -- Cập nhật totalPoints vào JSON
                    SET @NormalizedJSON = JSON_MODIFY(@NormalizedJSON, '$.totalPoints', @TotalPoints);

                    SET @Success = 1;
                    SET @Message = N'Chuẩn hóa JSON thành công';
                    SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] JSON normalized successfully. Total points: ', @TotalPoints, CHAR(13) + CHAR(10));
                END
                ELSE
                BEGIN
                    SET @Message = N'JSON vẫn không hợp lệ sau khi chuẩn hóa';
                    SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] JSON validation failed.', CHAR(13) + CHAR(10));
                END
            END
            ELSE
            BEGIN
                SET @Message = N'Không tìm thấy nội dung JSON trong response';
                SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] JSON content not found in response.', CHAR(13) + CHAR(10));
            END
        END
        ELSE
        BEGIN
            SET @Message = N'Response không đúng format: ' + LEFT(@AIResponse, 200);
            SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Invalid response format.', CHAR(13) + CHAR(10));
        END
    END TRY
    BEGIN CATCH
        SET @Message = ERROR_MESSAGE();
        SET @Success = 0;
        SET @ProcessingLog += CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] ERROR: ', @Message, CHAR(13) + CHAR(10));
    END CATCH

    SELECT 
        success = @Success,
        message = @Message,
        normalized_json = @NormalizedJSON,
        processing_log = @ProcessingLog,
        original_json_length = LEN(@InputJSON),
        normalized_json_length = LEN(@NormalizedJSON);
END;