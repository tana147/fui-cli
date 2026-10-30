-- FILE: spAPI_EL_Teacher_GetGradebook.sql
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Description:    API chính cho trang Sổ điểm. Trả về 3 bảng dữ liệu
--                 đã được xử lý để hiển thị dưới dạng crosstab.
--                 Sử dụng SQL Động và PIVOT, tương thích SQL Server 2016.
-- API Endpoint:   POST lms/el_teacher_getgradebook
-- Ví dụ Body:     { "LopID": "10A1", "MonHocID": 1 }
-- =================================================================================
-- [spAPI_EL_Teacher_GetGradebook] 5,32,''
create PROCEDURE [dbo].[spAPI_EL_Teacher_GetGradebook_OLD]
    @LopID VARCHAR(10),
    @MonHocID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN

    -- === Bước 1: Khai báo và kiểm tra quyền ===
    DECLARE @SqlStatement NVARCHAR(MAX);
    DECLARE @PivotColumns NVARCHAR(MAX);
	

    -- Kiểm tra giáo viên có dạy lớp và môn này không
    --IF NOT EXISTS (
    --    SELECT 1 FROM dbo.tblGiaoVienLop
    --    WHERE GiaoVienID = @sys_UserID AND LopID = @LopID AND MonHocID = @MonHocID AND Enable = 1
    --)
    --BEGIN
    --    RAISERROR(N'Bạn không có quyền xem sổ điểm cho lớp hoặc môn học này.', 16, 1);
    --    RETURN;
    --END

    -- === Bước 2: Chuẩn bị dữ liệu nguồn vào bảng tạm ===
    IF OBJECT_ID('tempdb..#GradebookData') IS NOT NULL DROP TABLE #GradebookData;
    
    -- Bảng tạm này sẽ chứa dữ liệu điểm số theo chiều dọc
    SELECT
        hsl.HocSinhID,
        hs.Ho + ' ' + hs.Ten AS HoTen,
        atc.AssignToClassID,
        -- Tạo chuỗi JSON nhỏ chứa trạng thái và điểm số
        CASE
            WHEN s.Score IS NOT NULL THEN 
                '{"status":"GRADED", "score":' + CAST(s.Score AS VARCHAR) + ', "submissionId":' + CAST(s.SubmissionID AS VARCHAR) + '}'
            WHEN s.SubmissionID IS NOT NULL THEN 
                '{"status":"PENDING", "submissionId":' + CAST(s.SubmissionID AS VARCHAR) + '}'
            ELSE 
                '{"status":"NOT_SUBMITTED"}'
        END AS ResultJSON
    INTO #GradebookData
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblHocSinh hs ON hsl.HocSinhID = hs.HocSinhID
    -- Dùng CROSS JOIN để tạo ra tất cả các cặp (học sinh, bài tập) có thể có
    CROSS JOIN dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    -- Sau đó LEFT JOIN với bài nộp thực tế
    LEFT JOIN dbo.tblEL_Submissions s ON hsl.HocSinhID = s.HocSinhID AND atc.AssignToClassID = s.AssignToClassID
    WHERE hsl.LopID = @LopID
      AND mhl.LopNhomID = @LopID
      AND mhl.MonHocID = @MonHocID
      AND hsl.Enable = 1
      AND atc.IsDeleted = 0;

    -- === BẢNG 1: TRẢ VỀ DANH SÁCH BÀI TẬP (để dựng Header cho bảng) ===
    SELECT DISTINCT
        atc.AssignToClassID,
        a.Title AS AssignmentTitle,
        atc.DueDate,
        atc.MaxScore
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND atc.IsDeleted = 0
    ORDER BY atc.DueDate;

    -- === BẢNG 2: TRẢ VỀ DỮ LIỆU ĐIỂM SỐ ĐÃ PIVOT ===
    -- Lấy danh sách các cột cần xoay (ví dụ: [123], [124], [125])
    SELECT @PivotColumns = STUFF(
        (
            SELECT DISTINCT ',' + QUOTENAME(CAST(AssignToClassID AS VARCHAR(20)))
            FROM #GradebookData
            FOR XML PATH('')
        ), 1, 1, ''
    );
    
    IF @PivotColumns IS NULL
    BEGIN
        -- Nếu chưa có bài tập nào được giao, trả về danh sách học sinh rỗng
        SELECT hs.HocSinhID, hs.Ho + ' ' + hs.Ten As HoTen 
		FROM dbo.tblHocSinhLop hsl JOIN dbo.tblHocSinh hs ON hsl.HocSinhID = hs.HocSinhID 
		WHERE hsl.LopID = @LopID AND hsl.Enable = 1;
    END
    ELSE
    BEGIN
        -- Viết câu lệnh SQL động hoàn chỉnh
        SET @SqlStatement = N'
        SELECT
            HocSinhID,
            HoTen,
            ' + @PivotColumns + '
        FROM (
            SELECT HocSinhID, HoTen, AssignToClassID, ResultJSON FROM #GradebookData
        ) AS SourceTable
        PIVOT (
            MAX(ResultJSON)
            FOR AssignToClassID IN (' + @PivotColumns + ')
        ) AS PivotTable
        ORDER BY HoTen;';

        EXEC sp_executesql @SqlStatement;
    END
    
    -- === BẢNG 3: TRẢ VỀ DỮ LIỆU THỐNG KÊ CỘT ===
    SELECT
        s.AssignToClassID,
        AVG(s.Score) AS AverageScore
    FROM dbo.tblEL_Submissions s
    JOIN dbo.tblMonHocLop mhl ON s.AssignToClassID IN (SELECT atc.AssignToClassID FROM tblEL_AssignToClass atc WHERE atc.MonHocLopID = mhl.MonHocLopID)
    WHERE mhl.LopNhomID = @LopID AND mhl.MonHocID = @MonHocID AND s.Score IS NOT NULL
    GROUP BY s.AssignToClassID;

    DROP TABLE #GradebookData;
END
