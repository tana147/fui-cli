CREATE PROCEDURE [dbo].[spAPI_CallGeminiAPI]
    @Prompt NVARCHAR(MAX),
    @Content NVARCHAR(MAX) 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @API_KEY NVARCHAR(500);
    DECLARE @Header NVARCHAR(MAX);
    DECLARE @RequestBody NVARCHAR(MAX);
    DECLARE @RawResponse NVARCHAR(MAX);
    DECLARE @URL NVARCHAR(1000);

    -- 1. DANH SÁCH 4 MODEL PHÂN TẦNG THEO THỨ TỰ YÊU CẦU
    DECLARE @ModelList TABLE (
        ID INT IDENTITY(1,1),
        ModelName NVARCHAR(100)
    );
    
INSERT INTO @ModelList (ModelName)
VALUES 
('gemini-3.1-flash-lite'),   -- Đẩy bản Lite đời mới lên đầu (Tốc độ xử lý cực nhanh, giá rẻ, bớt nghẽn)
('gemini-2.5-flash-lite'),   -- Dự phòng 1: Lite đời cũ ổn định
('gemini-3.5-flash'),        -- Dự phòng 2: Chỉ dùng tới khi các bản Lite từ chối dịch vụ
('gemini-2.5-flash');

    -- 2. Lấy API Key cấu hình từ hệ thống
    SELECT TOP 1 @API_KEY = API_KEY 
    FROM dbo.tblAI 
    WHERE Code = 'GEMINI';

    IF @API_KEY IS NULL OR @API_KEY = ''
    BEGIN
        SELECT 
            'ERROR'                                     AS [Status],
            'NO_API_KEY'                                AS [ErrorCode],
            N'Không tìm thấy API KEY cho GEMINI'        AS [ErrorMessage],
            NULL                                        AS [CleanResponse],
            NULL                                        AS [RawResponse];
        RETURN;
    END;

    SET @Header = CONCAT('X-Goog-Api-Key: ', @API_KEY);
    
    -- Chuẩn bị Request Body cấu trúc JSON chuẩn
    SET @RequestBody = N'{
        "systemInstruction": {
            "parts": [{ "text": "' + STRING_ESCAPE(@Prompt, 'json') + '" }]
        },
        "contents": [{
            "role": "user",
            "parts": [{ "text": "' + STRING_ESCAPE(@Content, 'json') + '" }]
        }],
        "generationConfig": {
            "responseMimeType": "application/json"
        }
    }';

    -- KHỞI TẠO KIỂM SOÁT THỜI GIAN (CHỐNG TREO GATEWAY 30S CỦA ỨNG DỤNG)
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @MaxExecutionSeconds INT = 22; -- Ngắt cưỡng bức trước 22 giây để kịp phản hồi về App

    -- Khởi tạo biến điều hướng vòng lặp chính
    DECLARE @CurrentIndex INT = 1;
    DECLARE @MaxIndex INT = (SELECT MAX(ID) FROM @ModelList);
    DECLARE @ActiveModel NVARCHAR(100);
    DECLARE @Success BIT = 0;
    
    -- Biến lưu trữ trạng thái lỗi và thông báo log
    DECLARE @IsQuotaError BIT = 0;
    DECLARE @IsOverloadedError BIT = 0;
    DECLARE @LastQuotaErrorMessage NVARCHAR(MAX) = '';

    -------------------------------------------------------------------------
    -- VÒNG LẶP CHÍNH: QUÉT QUA TỪNG MODEL (FALLBACK MECHANISM)
    -------------------------------------------------------------------------
    WHILE @CurrentIndex <= @MaxIndex AND @Success = 0
    BEGIN
        -- KIỂM TRA QUỸ THỜI GIAN: Nếu chạy lặp gần hết quỹ 22s -> Thoát luôn để bảo vệ Gateway
        IF DATEDIFF(SECOND, @StartTime, GETDATE()) > @MaxExecutionSeconds BREAK;

        SELECT @ActiveModel = ModelName FROM @ModelList WHERE ID = @CurrentIndex;
        SET @URL = CONCAT('https://generativelanguage.googleapis.com/v1beta/models/', @ActiveModel, ':generateContent');
        
        -- Cấu hình cơ chế Retry nhanh tức thì khi gặp lỗi bận hệ thống
        DECLARE @RetryCount INT = 0;
        DECLARE @MaxRetries INT = 1; -- Thử lượt đầu + tối đa 1 lượt retry = 2 lần gọi mạng/model
        DECLARE @NeedRetry BIT = 1;

        ---------------------------------------------------------------------
        -- VÒNG LẶP PHỤ: RETRY TỐI ĐA 1 LẦN NẾU GẶP LỖI 503 (KHÔNG TRÌ HOÃN / NO DELAY)
        ---------------------------------------------------------------------
        WHILE @RetryCount <= @MaxRetries AND @NeedRetry = 1
        BEGIN
            -- Kiểm tra quỹ thời gian trước khi bắn cuộc gọi mạng tiếp theo
            IF DATEDIFF(SECOND, @StartTime, GETDATE()) > @MaxExecutionSeconds 
            BEGIN
                SET @NeedRetry = 0;
                BREAK;
            END

            -- Thực thi gọi API thông qua hàm CLR
            SET @RawResponse = dbo.httpAPI('POST', @URL, @Header, @RequestBody);
            
            SET @IsQuotaError = 0;
            SET @IsOverloadedError = 0;
            SET @NeedRetry = 0; -- Mặc định giả định không cần thử lại nữa

            IF ISJSON(@RawResponse) > 0
            BEGIN
                -- BẮY CHÍNH XÁC LỖI 503 (CẢ TRỰC TIẾP LẪN TRONG RESPOND_DATA)
                IF JSON_VALUE(@RawResponse, '$.httpErrorCode') = '503'
                   OR JSON_VALUE(@RawResponse, '$.error.code') = '503'
                   OR JSON_VALUE(@RawResponse, '$.responseData.error.code') = '503'
                   OR JSON_VALUE(@RawResponse, '$.responseData.error.status') = 'UNAVAILABLE'
                   OR JSON_VALUE(@RawResponse, '$.error.status') = 'UNAVAILABLE'
                BEGIN
                    SET @IsOverloadedError = 1;
                    
                    IF @RetryCount < @MaxRetries
                    BEGIN
                        SET @RetryCount = @RetryCount + 1;
                        SET @NeedRetry = 1; 
                        CONTINUE; -- KHÔNG DÙNG WAITFOR DELAY -> Bắn lại request ngay lập tức!
                    END
                    ELSE
                    BEGIN
                        SET @NeedRetry = 0; -- Đã hết lượt retry, vòng lặp chính tự động SKIP sang model tiếp theo
                    END
                END

                -- BẮY LỖI 429 (HẾT HẠN MỨC CHI TIÊU / LƯỢT GỌI THEO PHÚT)
                IF JSON_VALUE(@RawResponse, '$.httpErrorCode') = '429'
                   OR JSON_VALUE(@RawResponse, '$.error.code') = '429'
                   OR JSON_VALUE(@RawResponse, '$.responseData.error.code') = '429'
                   OR JSON_VALUE(@RawResponse, '$.error.message') LIKE '%quota%'
                   OR JSON_VALUE(@RawResponse, '$.responseData.error.message') LIKE '%quota%'
                   OR JSON_VALUE(@RawResponse, '$.error.message') LIKE '%exhausted%'
                   OR JSON_VALUE(@RawResponse, '$.responseData.error.message') LIKE '%exhausted%'
                BEGIN
                    SET @IsQuotaError = 1;
                    SET @LastQuotaErrorMessage = ISNULL(
                        JSON_VALUE(@RawResponse, '$.error.message'), 
                        JSON_VALUE(@RawResponse, '$.responseData.error.message')
                    );
                END
                
                -- KIỂM TRA TRẠNG THÁI THÀNH CÔNG CỦA LƯỢT GỌI MẠNG
                IF @IsQuotaError = 0 AND @IsOverloadedError = 0
                   AND JSON_VALUE(@RawResponse, '$.httpErrorCode') IS NULL 
                   AND JSON_VALUE(@RawResponse, '$.error.code') IS NULL
                   AND JSON_VALUE(@RawResponse, '$.responseData.error.code') IS NULL
                BEGIN
                    SET @Success = 1;
                    BREAK; -- Thành công, thoát vòng lặp phụ
                END
            END
            ELSE
            BEGIN
                SET @NeedRetry = 0; -- Lỗi mạng cứng (Kết nối không phải JSON) -> Chuyển model dự phòng luôn
            END
        END -- Kết thúc vòng lặp phụ

        IF @Success = 1 BREAK; -- Thành công, thoát luôn vòng lặp chính

        -- Điều kiện chuyển dịch model: Nếu dính lỗi Quota HOẶC đã hết lượt retry lỗi 503
        IF @IsQuotaError = 1 OR @IsOverloadedError = 1
        BEGIN
            SET @CurrentIndex = @CurrentIndex + 1;
        END
        ELSE
        BEGIN
            -- Gặp các lỗi logic khác (Ví dụ: 400 Bad Request do viết sai cú pháp Prompt) -> Dừng luôn không đổi model
            BREAK;
        END
    END -- Kết thúc vòng lặp chính

    -------------------------------------------------------------------------
    -- 4. XỬ LÝ KẾT QUẢ TRẢ VỀ CUỐI CÙNG
    -------------------------------------------------------------------------
    
    -- TRƯỜNG HỢP ĐẶC BIỆT: BỊ NGẮT CƯỠNG BỨC DO CHẠM NGƯỠNG AN TOÀN TIMEOUT 22S
    IF @Success = 0 AND DATEDIFF(SECOND, @StartTime, GETDATE()) > @MaxExecutionSeconds
    BEGIN
        SELECT 
            'ERROR'              AS [Status],
            'TIMEOUT_PREVENTED'  AS [ErrorCode],
            N'Hệ thống AI phản hồi rất chậm. Vui lòng giảm bớt số lượng học sinh mỗi lượt quét hoặc gửi lại sau.' AS [ErrorMessage],
            NULL                 AS [CleanResponse],
            @RawResponse         AS [RawResponse];
        RETURN;
    END

    -- TRƯỜNG HỢP 1: TẤT CẢ MODEL TRONG DANH SÁCH ĐỀU THẤT BẠI
    IF @Success = 0 AND @CurrentIndex > @MaxIndex
    BEGIN
        DECLARE @WaitMessage NVARCHAR(MAX) = N'Hệ thống Google AI đang quá tải cục bộ hoặc hết hạn mức theo phút. Vui lòng đợi 1 đến 2 phút rồi thực hiện gửi lại.';

        SELECT 
            'ERROR'              AS [Status],
            'ALL_MODELS_FAILED'  AS [ErrorCode],
            @WaitMessage         AS [ErrorMessage],
            NULL                 AS [CleanResponse],
            @RawResponse         AS [RawResponse];
        RETURN;
    END

    -- TRƯỜNG HỢP 2: THÀNH CÔNG (Tương thích 100% với cơ chế "Thinking" của Gemini 3.1/3.5)
    IF @Success = 1
    BEGIN
        DECLARE @CleanedText NVARCHAR(MAX);

        -- Thử bóc tách trực tiếp theo cách chuẩn thông thường trước (parts[0])
        SET @CleanedText = JSON_VALUE(@RawResponse, '$.candidates[0].content.parts[0].text');

        -- Nếu dính các model có tính năng "Thinking", text thật sẽ bị đẩy lùi xuống cuối mảng parts
        IF @CleanedText IS NULL OR @CleanedText = ''
        BEGIN
            SELECT TOP 1 @CleanedText = [value]
            FROM (
                SELECT 
                    JSON_VALUE([value], '$.text') AS [value],
                    CAST([key] AS INT) AS [index_order]
                FROM OPENJSON(@RawResponse, '$.candidates[0].content.parts')
            ) AS Elements
            WHERE [value] IS NOT NULL AND [value] <> ''
            ORDER BY [index_order] DESC; -- Đảo ngược để lấy chính xác text kết quả cuối mảng parts
        END

        SELECT 
            'OK'                                                                AS [Status],
            NULL                                                                AS [ErrorCode],
            NULL                                                                AS [ErrorMessage],
            @CleanedText                                                        AS [CleanResponse],
            @RawResponse                                                        AS [RawResponse];
        RETURN;
    END

    -- TRƯỜNG HỢP 3: LỖI HỆ THỐNG KHÁC NGOÀI DỰ KIẾN (VÍ DỤ: 400 BAD REQUEST)
    IF ISJSON(@RawResponse) > 0
    BEGIN
        SELECT 
            'ERROR'                                                                                       AS [Status],
            ISNULL(JSON_VALUE(@RawResponse, '$.httpErrorCode'), ISNULL(JSON_VALUE(@RawResponse, '$.error.code'), JSON_VALUE(@RawResponse, '$.responseData.error.code'))) AS [ErrorCode],
            ISNULL(JSON_VALUE(@RawResponse, '$.error.message'), ISNULL(JSON_VALUE(@RawResponse, '$.responseData.error.message'), N'Lỗi hệ thống ngoài dự kiến')) AS [ErrorMessage],
            NULL                                                                                          AS [CleanResponse],
            @RawResponse                                                                                  AS [RawResponse];
    END
    ELSE
    BEGIN
        SELECT 'ERROR' AS [Status], 'NON_JSON' AS [ErrorCode], @RawResponse AS [ErrorMessage], NULL AS [CleanResponse], @RawResponse AS [RawResponse];
    END
END