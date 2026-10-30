
CREATE PROCEDURE [dbo].[spAPI_FP_AI_GenerateQuiz]
    @LoaiQuiz VARCHAR(50), -- Ví dụ: 'QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'
    @SoLuong INT,
    @NoiDungBaiHoc NVARCHAR(MAX),
    @sys_UserID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Xây dựng PROMPT cho AI một cách thông minh
    DECLARE @Prompt NVARCHAR(MAX);
    DECLARE @YeuCauChinh NVARCHAR(MAX);
    DECLARE @CauTrucJsonMau NVARCHAR(MAX);

    -- Lấy cấu trúc JSON mẫu từ bảng template chúng ta đã tạo
    -- Điều này giúp AI luôn trả về đúng định dạng
    SELECT @CauTrucJsonMau = TemplateJson 
    FROM dbo.tblTemplateDataJson_FP 
    WHERE LoaiNoiDung = @LoaiQuiz;

    IF @CauTrucJsonMau IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy mẫu JSON cho loại quiz: %s', 16, 1, @LoaiQuiz);
        RETURN;
    END

    SET @YeuCauChinh = CONCAT(
        N'Hãy tạo ra ', 
        CAST(@SoLuong AS NVARCHAR(10)), 
        N' câu hỏi dạng ', 
        @LoaiQuiz, 
        N' dựa trên nội dung được cung cấp. Câu trả lời của bạn PHẢI là một mảng JSON (JSON array) các object, mỗi object phải tuân thủ nghiêm ngặt cấu trúc JSON mẫu sau đây: ',
        @CauTrucJsonMau
    );
    
    SET @Prompt = N'{
        "Prompt": ' + dbo.JSON_Stringify(@YeuCauChinh) + N',
        "Content": ' + dbo.JSON_Stringify(@NoiDungBaiHoc) + N'
    }';

    -- Gọi API AI và trả kết quả về cho client
    SELECT dbo.httpAPI('POST', 'https://api.fap.vn/ai/auth/AI_Responses', '', @Prompt);

END
