CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetStudentSubmissionStatus]
    @AssignmentID INT,
    @AssignToClassID INT
AS
BEGIN
    SET NOCOUNT ON;

    ------ Kiểm tra quyền (chỉ người tạo bài tập mới xem được)
    IF NOT EXISTS (
        SELECT 1 
        FROM dbo.tblEL_Assignments a
        JOIN dbo.tblEL_AssignToClass atc ON a.AssignmentID = atc.AssignmentID
        WHERE a.AssignmentID = @AssignmentID
          AND atc.AssignToClassID = @AssignToClassID
    )
    BEGIN
        RAISERROR(N'[Unauthorized] Không tìm thấy bài tập hoặc lớp được giao.', 16, 1);
        RETURN;
    END

    -- Lấy danh sách học sinh và trạng thái nộp bài
    SELECT 
        hs.HocSinhID,
        hs.Ho +' ' + hs.Ten as HoTen,
        CASE 
            WHEN s.SubmissionID IS NOT NULL AND s.SubmissionStatus >= 2 THEN N'Đã nộp'
            ELSE N'Chưa nộp'
        END AS TrangThaiNop,
        s.AccessTime,
        s.DurationTime
    FROM dbo.tblHocSinhLop hsl
    JOIN dbo.tblHocSinh hs 
        ON hsl.HocSinhID = hs.HocSinhID
    JOIN dbo.tblMonHocLop mhl
        ON hsl.LopID = mhl.LopNhomID
    JOIN dbo.tblEL_AssignToClass atc
        ON mhl.MonHocLopID = atc.MonHocLopID
    LEFT JOIN dbo.tblEL_Submissions s 
        ON s.AssignToClassID = atc.AssignToClassID
        AND s.HocSinhID = hs.HocSinhID
        AND s.IsDeleted = 0
    WHERE 
        atc.AssignmentID = @AssignmentID
        AND atc.AssignToClassID = @AssignToClassID
        AND hsl.Enable = 1
    ORDER BY 
        Hoten;
END
