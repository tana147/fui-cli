-- FILE: spAPI_EL_Student_GetMyAssignedSubjects.sql
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Description:    Lấy danh sách các môn học (đã được gán bài học/bài tập)
--                 của một học sinh để dùng cho bộ lọc.
-- API Endpoint:   GET lms/el_student_getmyassignedsubjects
-- =================================================================================
CREATE  PROCEDURE [dbo].[spAPI_EL_Student_GetMyAssignedSubjects]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    

	DECLARE @HocSinhID_INT INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    DECLARE @LopID VARCHAR(10) = (SELECT TOP 1 LopID FROM dbo.tblHocSinhLop WHERE HocSinhID = @HocSinhID_INT AND Enable = 1);
    

    SELECT 
        0 AS MonHocID, 
        N'Tất cả môn học' AS MonHocName,
        -1 AS SortOrder 
    
    UNION
    
    -- Lấy danh sách các môn học duy nhất đã được gán tài nguyên
    SELECT DISTINCT
        mh.MonHocID, 
        mh.MonHocName,
        mh.Sort AS SortOrder
    FROM dbo.tblEL_AssignToClass atc
    -- Join để lấy MonHocID từ cả Lesson và Assignment
    INNER JOIN dbo.tblMonHocLop mhl ON atc.IsDeleted = 0 AND atc.MonHocLopID = mhl.MonHocLopID AND mhl.MonHocID = 
        CASE 
            WHEN atc.ResourceType = 'LESSON' THEN (SELECT MonHocID FROM tblEL_Lessons a  WHERE LessonID = atc.ResourceID)
            WHEN atc.ResourceType = 'ASSIGNMENT' THEN (SELECT MonHocID FROM tblEL_Assignments a WHERE AssignmentID = atc.ResourceID)
            ELSE NULL
        END
    INNER JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
    
    ORDER BY SortOrder, MonHocName;
END
