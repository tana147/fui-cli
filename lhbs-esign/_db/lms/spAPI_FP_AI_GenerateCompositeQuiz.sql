CREATE PROCEDURE [dbo].[spAPI_FP_AI_GenerateCompositeQuiz]
    @YeuCau NVARCHAR(MAX), -- Ví dụ: "Tạo 5 câu hỏi: 3 trắc nghiệm, 2 điền khuyết"
    @NoiDungBaiHoc NVARCHAR(MAX),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Prompt NVARCHAR(MAX);
    DECLARE @CauTrucJsonMau NVARCHAR(MAX);

    -- Lấy cấu trúc JSON mẫu của một bài QUIZ_COMPOSITE
    SELECT @CauTrucJsonMau = TemplateJson 
    FROM dbo.tblTemplateDataJson_FP 
    WHERE LoaiNoiDung = 'QUIZ_COMPOSITE';

    IF @CauTrucJsonMau IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy mẫu JSON cho loại quiz: QUIZ_COMPOSITE', 16, 1);
        RETURN;
    END

    -- Tạo prompt cho AI
    -- Hướng dẫn AI điền vào các phần của cấu trúc JSON mẫu
    SET @Prompt = CONCAT(
        N'Dựa vào nội dung văn bản được cung cấp, hãy thực hiện yêu cầu sau: "',
        @YeuCau,
        N'". Kết quả cuối cùng của bạn PHẢI là một object JSON duy nhất, tuân thủ nghiêm ngặt cấu trúc sau. Hãy tự điền các giá trị hợp lý vào các trường title, timeLimit, totalPoints, passingScore và đặc biệt là mảng questions: ',
        @CauTrucJsonMau
    );
    
    -- Tạo payload cuối cùng để gửi đi
    DECLARE @Payload NVARCHAR(MAX) = N'{
        "Prompt":' + dbo.JSON_Stringify(@Prompt) + ',
        "Content":' + dbo.JSON_Stringify(@NoiDungBaiHoc) + '
    }';

    -- Gọi API AI và trả kết quả
    SELECT dbo.httpAPI('POST', 'https://api.fap.vn/ai/auth/AI_Responses', '', @Payload);

END
