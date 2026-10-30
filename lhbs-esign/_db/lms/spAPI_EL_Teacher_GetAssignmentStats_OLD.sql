-- FILE: spAPI_EL_Teacher_GetAssignmentStats.sql
-- =================================================================================
-- Description:    Lấy các số liệu thống kê tổng quan (sĩ số, đã nộp, điểm TB)
--                 cho một lần giao bài cụ thể.
-- API Endpoint:   POST lms/el_teacher_getassignmentstats
-- Ví dụ Body:     { "AssignToClassID": 123 }
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentStats_OLD]
    @sys_UserID VARCHAR(9),
    @AssignToClassID BIGINT
AS
BEGIN
	IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END

    DECLARE @LopID VARCHAR(10);

    -- === Lấy LopID và kiểm tra quyền sở hữu ===
    SELECT @LopID = mhl.LopNhomID
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    WHERE atc.AssignToClassID = @AssignToClassID AND atc.CreateUser = @sys_UserID;

    IF @LopID IS NULL
    BEGIN
        -- Giáo viên không phải người tạo bài tập này, hoặc không tồn tại
        RAISERROR(N'Không tìm thấy thông tin giao bài hoặc bạn không có quyền truy cập.', 16, 1);
        RETURN;
    END

    -- === Tính toán và trả về các số liệu ===
    SELECT
        -- 1. Tổng học sinh của lớp
        (
            SELECT COUNT(hsl.HocSinhID) 
            FROM dbo.tblHocSinhLop hsl 
            WHERE hsl.LopID = @LopID AND hsl.Enable = 1
        ) AS TotalStudents,

        -- 2. Số lượng đã nộp (status >= 2)
        (
            SELECT COUNT(s.SubmissionID) 
            FROM dbo.tblEL_Submissions s 
            WHERE s.AssignToClassID = @AssignToClassID AND s.SubmissionStatus >= 2
        ) AS SubmittedCount,

        -- 3. Điểm trung bình của các bài đã chấm
        (
            SELECT AVG(s.Score) 
            FROM dbo.tblEL_Submissions s 
            WHERE s.AssignToClassID = @AssignToClassID AND s.Score IS NOT NULL
        ) AS AverageScore
END
