
-- FILE: spAPI_EL_Teacher_GetAssignmentCrosstabReport.sql
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    2025-08-16
-- Description:    Tạo báo cáo dạng crosstab (ma trận) cho một lần giao bài.
--                 Sử dụng SQL Động để pivot dữ liệu kết quả của học sinh.
--                 Trả về 2 bảng: Danh sách câu hỏi (header) và Bảng kết quả.
-- API Endpoint:   POST lms/el_teacher_getassignmentcrosstabreport
-- Ví dụ Body:     { "AssignToClassID": 123 }
-- =================================================================================
-- FILE: spAPI_EL_Teacher_GetAssignmentCrosstabReport.sql (SQL Server 2016 Compatible)
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    2025-08-16
-- Description:    Tạo báo cáo dạng crosstab.
--                 (v2) Sử dụng FOR XML PATH để tương thích với SQL Server 2016.
-- =================================================================================
-- FILE: spAPI_EL_Teacher_GetAssignmentCrosstabReport.sql (VERSION 4 - FINAL)
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    2025-08-16
-- Description:    Tạo báo cáo crosstab đầy đủ tính năng.
--                 Trả về 4 bảng: Header Info, Question List, Column Stats, và Crosstab Data.
--                 Sử dụng FOR XML PATH để tương thích với SQL Server 2016.
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentCrosstabReport_OLD]
    @AssignToClassID BIGINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- === Bước 1: Khai báo biến và kiểm tra quyền ===
    DECLARE @AssignmentConfig NVARCHAR(MAX), @LopID VARCHAR(10);
    DECLARE @SqlStatement NVARCHAR(MAX), @PivotColumns NVARCHAR(MAX);

    SELECT 
        @AssignmentConfig = ISNULL(atc.AssignmentConfig, a.AssignmentConfig),
        @LopID = mhl.LopNhomID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID 
	--AND atc.CreateUser = @sys_UserID;

    IF @AssignmentConfig IS NULL BEGIN RAISERROR(N'Không tìm thấy bài tập hoặc bạn không có quyền truy cập.', 16, 1); RETURN; END

    -- === BẢNG 1: THÔNG TIN HEADER ===
    SELECT
        l.TenLop AS ClassName,
        a.Title AS AssignmentTitle
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa
    WHERE atc.AssignToClassID = @AssignToClassID;

    -- === BẢNG 2: DANH SÁCH CÂU HỎI (Header của bảng) ===
    SELECT
        JSON_VALUE(q.value, '$.id') AS QuestionID_InJSON,
        JSON_VALUE(q.value, '$.config.questionText') AS QuestionTitle,
        JSON_VALUE(q.value, '$.type') AS QuestionType,
        CAST(JSON_VALUE(q.value, '$.points') AS DECIMAL(5, 2)) AS MaxScore
    FROM OPENJSON(@AssignmentConfig, '$.groups') g
    CROSS APPLY OPENJSON(g.value, '$.questions') q;

    -- === Bước 2: Chuẩn bị dữ liệu gốc trong bảng tạm ===
    IF OBJECT_ID('tempdb..#RawResults') IS NOT NULL DROP TABLE #RawResults;
    CREATE TABLE #RawResults (
        HocSinhID INT, HoTen NVARCHAR(255), SubmissionID BIGINT, FinalScore DECIMAL(5, 2),
        QuestionID_InJSON VARCHAR(50), ResultJSON NVARCHAR(255)
    );

    INSERT INTO #RawResults (HocSinhID, HoTen, SubmissionID, FinalScore, QuestionID_InJSON, ResultJSON)
    SELECT
        hsl.HocSinhID, hs.Ho + ' ' + hs.Ten, s.SubmissionID, s.Score, ar.QuestionID_InJSON,
        CASE
            WHEN ar.QuestionType LIKE '%CHOICE%' THEN
                CASE ar.IsCorrect WHEN 1 THEN '{"status":"CORRECT"}' WHEN 0 THEN '{"status":"INCORRECT"}' ELSE '{"status":"NOT_ANSWERED"}' END
            ELSE
                CASE
                    WHEN ar.Score IS NOT NULL THEN '{"status":"GRADED", "score":' + ISNULL(CAST(ar.Score AS VARCHAR), 'null') + '}'
                    WHEN s.SubmissionID IS NOT NULL THEN '{"status":"PENDING"}'
                    ELSE '{"status":"NOT_ANSWERED"}'
                END
        END
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblHocSinh hs ON hsl.HocSinhID = hs.HocSinhID
    LEFT JOIN dbo.tblEL_Submissions s ON hsl.HocSinhID = s.HocSinhID AND s.AssignToClassID = @AssignToClassID
    LEFT JOIN dbo.tblEL_Analytics_QuestionResults ar ON s.SubmissionID = ar.SubmissionID
    WHERE hsl.LopID = @LopID AND hsl.Enable = 1;
    
    -- === BẢNG 3: DỮ LIỆU THỐNG KÊ CỘT ===
    SELECT
        ar.QuestionID_InJSON,
        CAST(
            SUM(CASE WHEN ar.IsCorrect = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(ar.ResultID) 
            AS DECIMAL(5, 1)
        ) AS CorrectPercentage
    FROM dbo.tblEL_Analytics_QuestionResults ar
    WHERE ar.AssignToClassID = @AssignToClassID
      AND ar.QuestionID_InJSON IN (SELECT DISTINCT QuestionID_InJSON FROM #RawResults WHERE QuestionID_InJSON IS NOT NULL)
    GROUP BY ar.QuestionID_InJSON;
    
    -- === Bước 3: Xây dựng và thực thi SQL Động để tạo BẢNG 4 ===
    SELECT @PivotColumns = STUFF((SELECT DISTINCT ',' + QUOTENAME(QuestionID_InJSON) FROM #RawResults WHERE QuestionID_InJSON IS NOT NULL FOR XML PATH('')), 1, 1, '');

    IF @PivotColumns IS NULL
    BEGIN
        -- Trả về bảng rỗng nếu không có dữ liệu để pivot
        SELECT hs.HocSinhID, hs.Ho + ' ' + hs.Ten as HoTen, NULL AS FinalScore, NULL AS SubmissionID 
		FROM dbo.tblHocSinhLop hsl 
		JOIN dbo.tblHocSinh hs ON hsl.HocSinhID = hs.HocSinhID 
		WHERE hsl.LopID = @LopID AND hsl.Enable=1;
    END
    ELSE
    BEGIN
        SET @SqlStatement = N'
        SELECT
            HocSinhID,
            HoTen,
            SubmissionID,
            FinalScore,
            ' + @PivotColumns + '
        FROM (
            -- Dữ liệu nguồn cho PIVOT, bao gồm cả các cột không được pivot
            SELECT HocSinhID, HoTen, SubmissionID, FinalScore, QuestionID_InJSON, ResultJSON
            FROM #RawResults
        ) AS SourceTable
        PIVOT (
            -- Hàm tổng hợp cho PIVOT
            MAX(ResultJSON)
            FOR QuestionID_InJSON IN (' + @PivotColumns + ')
        ) AS PivotTable
        ORDER BY HoTen;';

        EXEC sp_executesql @SqlStatement;
    END

    DROP TABLE #RawResults;

END
