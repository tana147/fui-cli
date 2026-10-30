create PROCEDURE [dbo].[spAPI_EL_Student_GetMyResources_OLD]
    @sys_UserID VARCHAR(9),
    @MonHocID INT = 0,
    @StatusFilter VARCHAR(20) = 'ALL' -- 'ALL', 'COMPLETED', 'INCOMPLETE'
AS
BEGIN
    SET NOCOUNT ON;

	-- Dùng cho mục đích debug, có thể xóa sau
    DECLARE @HocSinhID INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @LopID VARCHAR(10) = (SELECT TOP 1 l.LopID FROM dbo.tblHocSinhLop hsl JOIN tblLop l ON hsl.LopID = l.LopID WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND l.NienKhoa = @NienKhoa);

    -- Bước 1: Dùng CTE để lấy danh sách tất cả các tài nguyên (Assignments & Lessons) đã được giao cho lớp của học sinh.
    WITH AssignedResources AS (
        SELECT 
            atc.AssignToClassID,
            atc.ResourceType,
            atc.ResourceID,
            mhl.MonHocID
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        WHERE mhl.LopNhomID = @LopID AND atc.IsDeleted = 0
    )

    -- Bước 2: Dùng UNION ALL để tổng hợp và trả về kết quả cuối cùng.
    SELECT * FROM (
        -- Lấy danh sách BÀI GIẢNG (Lessons)
        SELECT
            ar.AssignToClassID,
            ar.ResourceType,
            ar.ResourceID,
            l.Title,
            l.Description,
            l.ThumbnailURL,
            mh.MonHocName,
            mh.MonHocID,
            -- Trạng thái hoàn thành
            CAST(ISNULL(lp.IsCompleted, 0) AS BIT) AS IsCompleted,
            -- Thời gian tương tác cuối cùng
            lp.LastAccessed
        FROM AssignedResources ar
        JOIN dbo.tblEL_Lessons l ON ar.ResourceID = l.LessonID AND ar.ResourceType = 'LESSON'
        JOIN dbo.tblMonHoc mh ON ar.MonHocID = mh.MonHocID
        LEFT JOIN dbo.tblEL_Learning_Progress lp ON ar.ResourceID = lp.LessonID AND lp.HocSinhID = @HocSinhID
        WHERE l.IsDeleted = 0 AND l.Status = 2 -- Chỉ lấy bài đã xuất bản

        UNION ALL

        -- Lấy danh sách BÀI TẬP (Assignments)
        SELECT
            ar.AssignToClassID,
            ar.ResourceType,
            ar.ResourceID,
            a.Title,
            a.Instructions AS Description,
            NULL AS ThumbnailURL,
            mh.MonHocName,
            mh.MonHocID,
            -- Trạng thái hoàn thành (đã nộp hoặc đã chấm)
            CAST(CASE WHEN s.SubmissionStatus >= 2 THEN 1 ELSE 0 END AS BIT) AS IsCompleted,
            -- Thời gian tương tác cuối cùng
            s.SubmissionTime
        FROM AssignedResources ar
        JOIN dbo.tblEL_Assignments a ON ar.ResourceID = a.AssignmentID AND ar.ResourceType = 'ASSIGNMENT'
        JOIN dbo.tblMonHoc mh ON ar.MonHocID = mh.MonHocID
        -- SỬA LỖI LOGIC: Join với tblEL_Submissions qua AssignToClassID
        LEFT JOIN dbo.tblEL_Submissions s ON ar.AssignToClassID = s.AssignToClassID AND s.HocSinhID = @HocSinhID
        WHERE a.IsDeleted = 0
    ) AS FinalResults
    WHERE
        -- Áp dụng bộ lọc Môn học
        (@MonHocID = 0 OR FinalResults.MonHocID = @MonHocID)
        -- Áp dụng bộ lọc Trạng thái
        AND (@StatusFilter = 'ALL' 
             OR (@StatusFilter = 'COMPLETED' AND IsCompleted = 1)
             OR (@StatusFilter = 'INCOMPLETE' AND IsCompleted = 0)
            )
    ORDER BY 
        LastAccessed DESC;

END
