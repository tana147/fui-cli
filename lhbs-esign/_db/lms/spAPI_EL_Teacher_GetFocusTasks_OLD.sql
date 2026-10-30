-- FILE: spAPI_EL_Teacher_GetFocusTasks.sql
-- =================================================================================
-- Description:    Lấy danh sách các bài tập quan trọng cần giáo viên chú ý
--                 (cần chấm, sắp hết hạn, tỉ lệ nộp thấp).
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetFocusTasks_OLD]
    @sys_UserID VARCHAR(9)
AS
BEGIN
   IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END

   ; WITH AssignmentMetrics AS (
        SELECT
            atc.AssignToClassID,
            m.MonHocID,
            l.LopID,
            a.Title,
            m.MonHocName,
            l.TenLop,
            atc.DueDate,
            (SELECT COUNT(s.SubmissionID) FROM dbo.tblEL_Submissions s WHERE s.AssignToClassID = atc.AssignToClassID AND s.SubmissionStatus >= 2) AS SubmittedCount,
            (SELECT COUNT(s.SubmissionID) FROM dbo.tblEL_Submissions s WHERE s.AssignToClassID = atc.AssignToClassID AND s.SubmissionStatus = 2 AND s.Score IS NULL) AS PendingGradingCount,
            (SELECT COUNT(hsl.HocSinhID) FROM dbo.tblHocSinhLop hsl WHERE hsl.LopID = mhl.LopNhomID AND hsl.Enable = 1) AS TotalStudents
        FROM dbo.tblEL_AssignToClass atc
        JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
        JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
        JOIN dbo.tblMonHoc m ON mhl.MonHocID = m.MonHocID
        JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa
        WHERE atc.CreateUser = @sys_UserID AND atc.IsDeleted = 0
    )
    SELECT TOP 5
        AssignToClassID,
        Title,
        MonHocName,
        MonHocID,
        TenLop,
        LopID,
        DueDate,
        SubmittedCount,
        PendingGradingCount,
        TotalStudents,
        -- Xác định trạng thái để frontend có thể hiển thị màu sắc
        CASE
            WHEN PendingGradingCount > 0 THEN 'PENDING_GRADING' -- Ưu tiên cao nhất
            WHEN DueDate < GETDATE() THEN 'OVERDUE'
            ELSE 'UPCOMING'
        END AS Status
    FROM AssignmentMetrics
    -- Sắp xếp ưu tiên: Cần chấm > Quá hạn > Sắp hết hạn
    ORDER BY
        CASE WHEN PendingGradingCount > 0 THEN 0 ELSE 1 END,
        DueDate ASC;
END
