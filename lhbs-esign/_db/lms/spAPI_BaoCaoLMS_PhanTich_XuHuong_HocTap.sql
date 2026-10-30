CREATE PROC [dbo].[spAPI_BaoCaoLMS_PhanTich_XuHuong_HocTap]
	@NoiDung NVARCHAR(max)
AS
BEGIN
 -- ===============================
-- 1. Khai báo biến
-- ===============================
DECLARE @Prompt NVARCHAR(MAX);
DECLARE @CauTrucJsonMau NVARCHAR(MAX); 
DECLARE @APIResult NVARCHAR(MAX);
DECLARE @Response NVARCHAR(MAX);
DECLARE @NhanXet NVARCHAR(MAX);

-- ===============================
-- 2. Cấu trúc JSON mẫu chỉ cần NhanXet
-- ===============================
SET @CauTrucJsonMau = N'{
    "NhanXet": "string (nhận xét chi tiết, dễ hiểu về xu hướng học tập; kết luận rõ ràng: tăng, giảm, ổn định)"
}';

-- ===============================
-- 3. Dữ liệu bài tập (JS object literal, key không dấu "")
-- ===============================
--SET @NoiDungBaiHoc = '[
--    {
--        series: [
--            {
--                name: "Bài tập",
--                data: [100, 80, 100, null, 91.67, null, null],
--                group: "apexcharts-axis-0"
--            }
--        ],
--        xaxis: {
--            categories: [
--                "LISTENING PRACTICE",
--                "READING PRACTICE",
--                "SEM1-TERM 1-REVISION",
--                "REVISION 2",
--                "LISTENING CEP REVIEW",
--                "Speaking",
--                "LISTENING REVISION"
--            ]
--        }
--    }
--]';

-- ===============================
-- 4. Xây dựng Prompt yêu cầu AI trả về nhận xét dài + kết luận xu hướng
-- ===============================
SET @Prompt = N'{
    "Prompt": ' + dbo.JSON_Stringify(
        N'Hãy phân tích dữ liệu bài tập học sinh được cung cấp. '
        + N'Trả về JSON array với trường NhanXet. '
        + N'Nội dung NhanXet phải bao gồm: 1) nhận xét chi tiết, dễ hiểu về điểm số từng bài, điểm mạnh, điểm cần cải thiện, '
        + N'2) KẾT LUẬN RÕ RÀNG về xu hướng học tập: "tăng", "giảm" hoặc "ổn định". '
        + N'Ví dụ: "Học sinh có điểm cao ở các bài đầu, nhưng giảm ở các bài sau. Kết luận: xu hướng học tập giảm – cần cải thiện các bài chưa hoàn thành."'
    ) + N',
    "Content": ' + dbo.JSON_Stringify(@NoiDung) + N'
}';

-- ===============================
-- 5. Gọi API AI
-- ===============================
SET @APIResult = dbo.httpAPI('POST', 'https://api.fap.vn/ai/auth/AI_Responses', '', @Prompt);
-- ===============================
-- 6. Lấy Response từ mảng data
-- ===============================
SELECT TOP 1 @Response = JSON_VALUE([value], '$.Response')
FROM OPENJSON(@APIResult, '$.data');

-- Loại bỏ ```json nếu có
SET @Response = REPLACE(@Response, '```json', '');
SET @Response = REPLACE(@Response, '```', '');

-- ===============================
-- 7. Parse Response để lấy NhanXet
-- ===============================
SELECT NhanXet
FROM OPENJSON(@Response)
WITH (NhanXet NVARCHAR(MAX) '$.NhanXet') AS N;

END
   