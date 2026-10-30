CREATE PROCEDURE [dbo].[spAPI_FP_AI_WordToQuizJSON_Extract_FromHTML_CHUNK_1]
    @HtmlContent NVARCHAR(MAX),
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
    END;

    DECLARE @Prompt NVARCHAR(MAX) = N'
Tôi có một đề thi trắc nghiệm được sao chép từ Word dưới dạng HTML. Hãy phân tích và TRẢ VỀ DUY NHẤT MỘT CHUỖI JSON hợp lệ theo định dạng sau (KHÔNG GIẢI THÍCH, KHÔNG THÊM CHỮ DẪN).

---

## ✅ CẤU TRÚC JSON CẦN TRẢ VỀ:

  "questions": [
    { ... },
    {
      "type": "QUIZ_GROUP",
      "title": "PHẦN I. Trắc nghiệm",
      "questions": [ ... ]
    }
  ]

---

## ✅ CÁC LOẠI CÂU HỎI HỖ TRỢ:

### QUIZ_SINGLE_CHOICE:
{
  "id": "q1",
  "type": "QUIZ_SINGLE_CHOICE",
  "points": 1,
  "content": {
    "prompt": "<p><strong>Câu 1.</strong> Nội dung câu hỏi</p>",
    "options": [
      { "id": "a", "text": "[Đáp án A]" },
      { "id": "b", "text": "[Đáp án B]" },
      { "id": "c", "text": "[Đáp án C]" },
      { "id": "d", "text": "[Đáp án D]" },
    "correctAnswer": "b"
  }
}

### QUIZ_MULTIPLE_CHOICE:
{
  "id": "q2",
  "type": "QUIZ_MULTIPLE_CHOICE",
  "points": 1,
  "content": {
    "prompt": "...",
    "options": [
      { "id": "a", "text": "[Đáp án A]" },
      { "id": "b", "text": "[Đáp án B]" },
      { "id": "c", "text": "[Đáp án C]" },
      { "id": "d", "text": "[Đáp án D]" }
    "correctAnswers": ["a", "c"]
  }
}

### QUIZ_FILL_IN_BLANK:
{
  "id": "q3",
  "type": "QUIZ_FILL_IN_BLANK",
  "points": 1,
  "content": {
    "prompt": "...",
    "parts": [
      { "type": "text", "value": "..." },
      { "type": "blank", "id": "...", "correctAnswer": "...", "size": 10 }
    ]
  }
}

### QUIZ_GROUP:
{
  "type": "QUIZ_GROUP",
  "title": "PHẦN I...",
  "questions": [ ... ]
}

---

### ✅ QUY TẮC PHÂN TÍCH:
1. Mỗi câu hỏi bắt đầu bằng `<strong>Câu X.</strong>` hoặc `Câu X.`
2. Câu hỏi có thể chứa bảng (`<table>`) hoặc hình ảnh (`<img>`) → PHẢI giữ nguyên trong `prompt`
3. Đáp án đúng được đánh dấu bằng:
   - Gạch chân: thẻ `<u>...</u>`
   - In đậm: thẻ `<strong>...</strong>`
   - Hoặc cả hai lồng nhau `<strong><u>...</u></strong>`
   - Loại bỏ các thẻ này ra khỏi đáp án
4. Trong `options`, mỗi đáp án có `id` lần lượt là `"a"`, `"b"`, `"c"`, `"d"`, nội dung là **text sạch** (loại bỏ các thẻ như `<strong>`, `<u>` khỏi nội dung đáp án)
5. Nếu đề có phần như "PHẦN I", "PHẦN II" hoặc "Bài A", thì hãy dùng `"type": "QUIZ_GROUP"` và `"title"` là tiêu đề nhóm đó.

6. Nếu là dạng trắc nghiệm nhiều đáp án đúng → dùng `"type": "QUIZ_MULTIPLE_CHOICE"` và `"correctAnswers": ["a", "c"]`

7. Nếu là dạng điền chỗ trống có cấu trúc → dùng `"type": "QUIZ_FILL_IN_BLANK"` và tách `parts` (text/blank).

---

### ❌ Tuyệt đối KHÔNG trả về:
- Markdown
- Chú thích, giải thích
- Phần mô tả ngoài JSON
- Dạng `"options": ["A. ...", "B. ..."]` (không chấp nhận)
-
---

Dưới đây là nội dung HTML đề thi cần xử lý:
' + @HtmlContent;

  

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

        SET @ProcessingLog = CONCAT('[', FORMAT(GETDATE(), 'HH:mm:ss'), '] Claude response received.', CHAR(13) + CHAR(10));

        IF @AIResponse LIKE '%"content":%' AND @AIResponse LIKE '%"text":%'
        BEGIN
            DECLARE @StartPos INT = CHARINDEX('"text":"', @AIResponse) + 8;
            DECLARE @EndPos INT = CHARINDEX('"}]', @AIResponse, @StartPos);

            IF @StartPos > 8 AND @EndPos > @StartPos
            BEGIN
                SET @QuizJSON = SUBSTRING(@AIResponse, @StartPos, @EndPos - @StartPos);

                -- Fix escape Claude (bên ngoài): \" => "
                SET @QuizJSON = REPLACE(@QuizJSON, '\\"', '"');

                -- Chuẩn hoá xuống dòng
                SET @QuizJSON = REPLACE(@QuizJSON, '\\n', '');
                SET @QuizJSON = REPLACE(@QuizJSON, '\\r', '');
                SET @QuizJSON = REPLACE(@QuizJSON, '\\t', '');
                SET @QuizJSON = REPLACE(@QuizJSON, CHAR(10), '');
                SET @QuizJSON = REPLACE(@QuizJSON, CHAR(13), '');

                -- Ghép JSON nếu bị nối sai
                SET @QuizJSON = REPLACE(@QuizJSON, '}{', '},{');

                -- Escape dấu " trong prompt/text
                DECLARE @pos INT = 1, @s NVARCHAR(MAX), @found INT;

                WHILE CHARINDEX('"prompt":"', @QuizJSON, @pos) > 0
                BEGIN
                    SET @found = CHARINDEX('"prompt":"', @QuizJSON, @pos);
                    SET @found = @found + 9;
                    SET @pos = CHARINDEX('"', @QuizJSON, @found);
                    WHILE @pos > 0 AND SUBSTRING(@QuizJSON, @pos - 1, 1) = '\'
                        SET @pos = CHARINDEX('"', @QuizJSON, @pos + 1);
                    IF @pos = 0 BREAK;
                    SET @s = SUBSTRING(@QuizJSON, @found, @pos - @found);
                    SET @s = REPLACE(@s, '"', '\"');
                    SET @QuizJSON = STUFF(@QuizJSON, @found, @pos - @found, @s);
                    SET @pos = @found + LEN(@s);
                END

                -- Bọc ngoặc
                IF LEFT(LTRIM(@QuizJSON), 1) <> '{'
                    SET @QuizJSON = '{' + @QuizJSON + '}';

                -- Thêm info nếu thiếu
                IF CHARINDEX('"questions":', @QuizJSON) > 0 AND CHARINDEX('"title":', @QuizJSON) = 0
                BEGIN
                    SET @QuizJSON = STUFF(@QuizJSON, 2, 0,
                        '"title": ' + dbo.JSON_Stringify(@TieuDe) + ',' +
                        '"timeLimit": ' + CAST(@ThoiGianLam * 60 AS NVARCHAR) + ',' +
                        '"totalPoints": 0,' +
                        '"passingScore": 0,'
                    );
                END

                IF ISJSON(@QuizJSON) = 1
                BEGIN
                    SET @Success = 1;
                    SET @Message = N'Trích xuất thành công';
                END
                ELSE
                BEGIN
                    SET @Message = N'JSON lỗi sau khi làm sạch';
                END
            END
            ELSE
            BEGIN
                SET @Message = N'KHông tìm thấy text JSON';
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
        SET @ProcessingLog += '[ERROR] ' + @Message;
    END CATCH

    SELECT 
        success = @Success,
        message = @Message,
        quiz_json = @QuizJSON,
        processing_log = @ProcessingLog;
END;
