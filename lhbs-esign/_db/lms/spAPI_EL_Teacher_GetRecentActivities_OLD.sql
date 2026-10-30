
CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetRecentActivities_OLD] 
    @sys_UserID VARCHAR(9),
    @LopID VARCHAR(10) = NULL,
    @MonHocID INT = NULL,
    @PageSize INT = 15
AS
BEGIN
    SET NOCOUNT ON;
	
 SET @sys_UserID = 'NV0000244'
    DECLARE @NienKhoa_HienTai INT = dbo.fn_GetNienKhoa_HienTai();

    -- Sử dụng CTE để tìm ra các cặp (LopID, MonHocID) mà giáo viên này đang dạy trong niên khóa hiện tại
    WITH TeacherAssignments AS (
        SELECT DISTINCT LopID, MonHocID
        FROM dbo.tblGiaoVienLop
        WHERE GiaoVienID = @sys_UserID
          AND NienKhoa = @NienKhoa_HienTai
          AND Enable = 1
    )
    -- Lấy ra N hoạt động gần đây nhất
    SELECT TOP (@PageSize)
        al.ActivityID,
        al.CreateTime AS Timestamp,
        hs.Ho + ' ' + hs.Ten AS StudentName,
        l.TenLop AS ClassName,
        al.ActivityType,
        
        CASE al.ResourceType
            WHEN 'ASSIGNMENT' THEN (SELECT Title FROM dbo.tblEL_Assignments WHERE AssignmentID = al.ResourceID)
            WHEN 'LESSON' THEN (SELECT Title FROM dbo.tblEL_Lessons WHERE LessonID = al.ResourceID)
            WHEN 'SUBMISSION' THEN (
                SELECT a.Title 
                FROM dbo.tblEL_Submissions s
                JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID
                JOIN dbo.tblEL_Assignments a ON atc.AssignmentID = a.AssignmentID
                WHERE s.SubmissionID = al.ResourceID
            )
            ELSE NULL
        END AS ResourceTitle,
        
        mh.MonHocName, -- Thêm tên môn học để hiển thị rõ hơn
        NULL AS AvatarURL 

    FROM 
        dbo.tblEL_Activity_Logs AS al
    JOIN 
        dbo.tblHocSinh AS hs ON al.HocSinhID = hs.HocSinhID
    JOIN 
        dbo.tblHocSinhLop AS hsl ON al.HocSinhID = hsl.HocSinhID AND hsl.Enable = 1
    JOIN
        dbo.tblLop as l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa_HienTai
    JOIN
		tblMonHocLop mhl ON mhl.LopNhomID = l.LopID
	JOIN
        dbo.tblMonHoc as mh ON mh.MonHocID = mhl.MonHocID
    WHERE
        EXISTS (
            SELECT 1
            FROM TeacherAssignments ta
            WHERE ta.LopID = hsl.LopID
              AND (
                  ta.MonHocID = mh.MonHocID -- Join với môn học từ tblLop
                  -- Hoặc nếu là GVCN cấp 1 (dạy nhiều môn), MonHocID trong tblGiaoVienLop có thể là NULL hoặc 0
                  OR ta.MonHocID IS NULL
              )
        )
        
        -- Các bộ lọc tùy chọn
        AND (@LopID IS NULL OR hsl.LopID = @LopID)
        AND (@MonHocID IS NULL OR mh.MonHocID = @MonHocID)
        
    ORDER BY
        al.CreateTime DESC;

END
