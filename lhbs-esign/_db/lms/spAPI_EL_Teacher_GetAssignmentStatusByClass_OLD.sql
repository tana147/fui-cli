
-- FILE: spAPI_EL_Teacher_GetAssignmentStatusByClass.sql
-- =================================================================================
-- Description:    Lấy thông tin của một bài tập và trạng thái giao bài cho từng lớp.
-- API Endpoint:   GET lms/el_teacher_getassignmentstatusbyclass?AssignmentID=1
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetAssignmentStatusByClass_OLD]
    @AssignmentID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
	IF @sys_UserID = 'NA0000022'
	BEGIN
		SET @sys_UserID = 'NV0000907'
	END
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();

    -- === LOGIC PHÂN QUYỀN ===
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Assignments WHERE AssignmentID = @AssignmentID AND CreateUser = @sys_UserID)
    BEGIN
        RAISERROR(N'[Unauthorized] Bạn không có quyền xem thông tin bài tập này.', 16, 1);
        RETURN;
    END

    -- === Bảng 1: Thông tin chi tiết của Bài tập gốc ===
    SELECT 
        AssignmentID,
        Title,
        Instructions,
        MonHocID,
        KhoiID,
        NienKhoa,
        HocKi
    FROM dbo.tblEL_Assignments
    WHERE AssignmentID = @AssignmentID;

    -- === Bảng 2: Danh sách các lớp đã được giao và tiến độ nộp bài ===
    WITH ClassSubmissions AS (
        -- Đếm số học sinh đã nộp bài (status >= 2) cho mỗi lần giao
        SELECT 
            AssignToClassID,
            COUNT(SubmissionID) AS SubmittedCount
        FROM dbo.tblEL_Submissions
        WHERE IsDeleted = 0 AND SubmissionStatus >= 2
        GROUP BY AssignToClassID
    )
    SELECT 
        atc.AssignToClassID,
        atc.MonHocLopID,
        l.TenLop,
        atc.DueDate,
        -- Đếm sĩ số của lớp tại thời điểm hiện tại
        (SELECT COUNT(*) FROM dbo.tblHocSinhLop hsl WHERE hsl.LopID = l.LopID AND hsl.Enable = 1) AS TotalStudents,
        ISNULL(cs.SubmittedCount, 0) AS SubmittedCount
    FROM dbo.tblEL_AssignToClass atc
    JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID
    LEFT JOIN ClassSubmissions cs ON atc.AssignToClassID = cs.AssignToClassID
    WHERE 
        atc.AssignmentID = @AssignmentID
        AND atc.IsDeleted = 0
        AND l.NienKhoa = @NienKhoa -- Chỉ lấy các lớp trong niên khóa hiện tại
    ORDER BY
        l.TenLop;
END
