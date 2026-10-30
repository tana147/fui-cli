CREATE PROCEDURE [dbo].[spAPI_EL_Student_Get_TienDo_ByHocSinhID]
@HocSinhID INT,
@NienKhoa int
AS
BEGIN
  SET NOCOUNT ON;
  DECLARE @MyUnits TABLE (UnitID VARCHAR(100));
    INSERT INTO @MyUnits (UnitID)
    -- Lấy Lớp chính thức
    SELECT hsl.LopID FROM dbo.tblHocSinhLop hsl JOIN dbo.tblLop l ON hsl.LopID = l.LopID AND l.NienKhoa = @NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE hsl.HocSinhID = @HocSinhID AND hsl.Enable = 1 AND hsl.NienKhoa = @NienKhoa
    UNION 
    -- Lấy các Nhóm học tập
    SELECT hsn.NhomID FROM dbo.tblHocSinhNhom hsn JOIN dbo.tblNhom n ON hsn.NhomID = n.NhomID AND n.NienKhoa = @NienKhoa
    WHERE hsn.HocSinhID = @HocSinhID AND hsn.Enable = 1;
 WITH AllTasks AS (
		SELECT MonHocID, SUM(TotalCount) AS TotalCount FROM (
			-- Đếm số BÀI TẬP (Assignments) duy nhất
			SELECT a.MonHocID, COUNT(DISTINCT atc.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToClass atc 
			JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID
			WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM tblMonHocLop WHERE NienKhoa = @NienKhoa AND LopNhomID IN (SELECT UnitID FROM @MyUnits))
			  AND atc.IsDeleted = 0 and a.IsDeleted = 0 AND atc.ResourceType = 'ASSIGNMENT' 
			GROUP BY a.MonHocID
        
			UNION ALL

			SELECT a.MonHocID, COUNT(DISTINCT ats.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToStudent ats
			JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID
			WHERE ats.MonHocLopID IN (SELECT MonHocLopID FROM tblMonHocLop WHERE NienKhoa = @NienKhoa AND LopNhomID IN (SELECT UnitID FROM @MyUnits))
			AND ats.IsDeleted = 0 and a.IsDeleted = 0 AND ats.ResourceType = 'ASSIGNMENT' AND ats.HocSinhID = @HocSinhID
			GROUP BY a.MonHocID

			UNION ALL
        
			-- Đếm số BÀI HỌC (Lessons) duy nhất
			SELECT l.MonHocID, COUNT(DISTINCT atc.ResourceID) AS TotalCount 
			FROM dbo.tblEL_AssignToClass atc 
			JOIN dbo.tblEL_Lessons l ON atc.ResourceID = l.LessonID
			WHERE atc.MonHocLopID IN (SELECT MonHocLopID FROM tblMonHocLop WHERE NienKhoa = @NienKhoa AND LopNhomID IN (SELECT UnitID FROM @MyUnits))
			  AND atc.IsDeleted = 0 and l.IsDeleted = 0 AND atc.ResourceType = 'LESSON'
			GROUP BY l.MonHocID
		) t GROUP BY MonHocID 
	),
	CompletedTasks AS (
		-- CTE này đã đúng vì nó đếm theo kết quả của học sinh, vốn đã là duy nhất
		-- nên không cần sửa.
		SELECT MonHocID, SUM(CompletedCount) AS CompletedCount FROM (
			SELECT a.MonHocID, COUNT(DISTINCT atc.ResourceID) AS CompletedCount
			FROM dbo.tblEL_Submissions s
			JOIN dbo.tblEL_AssignToClass atc ON s.AssignToClassID = atc.AssignToClassID and atc.IsDeleted = 0
			JOIN dbo.tblEL_Assignments a ON atc.ResourceID = a.AssignmentID AND atc.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
			WHERE s.HocSinhID = @HocSinhID
			  AND s.SubmissionStatus >= 2
			  AND s.IsDeleted = 0
			  AND atc.MonHocLopID IN (
				  SELECT MonHocLopID FROM dbo.tblMonHocLop
				  WHERE NienKhoa = @NienKhoa
					AND LopNhomID IN (SELECT UnitID FROM @MyUnits)
			  )
			GROUP BY a.MonHocID

			UNION ALL
            
			SELECT a.MonHocID, COUNT(DISTINCT ats.ResourceID) AS CompletedCount
			FROM dbo.tblEL_Submissions s
			JOIN dbo.tblEL_AssignToStudent ats ON s.AssignToStudentID = ats.AssignToStudentID and ats.IsDeleted = 0
			JOIN dbo.tblEL_Assignments a ON ats.ResourceID = a.AssignmentID AND ats.ResourceType = 'ASSIGNMENT' and a.IsDeleted = 0
			WHERE s.HocSinhID = @HocSinhID
			  AND s.SubmissionStatus >= 2
			  AND s.IsDeleted = 0
			  AND ats.HocSinhID = @HocSinhID
			  AND ats.MonHocLopID IN (
				  SELECT MonHocLopID FROM dbo.tblMonHocLop
				  WHERE NienKhoa = @NienKhoa
					AND LopNhomID IN (SELECT UnitID FROM @MyUnits)
			  )
			GROUP BY a.MonHocID

			UNION ALL

			SELECT l.MonHocID, COUNT(DISTINCT lp.LessonID) AS CompletedCount
			FROM dbo.tblEL_Learning_Progress lp
			JOIN dbo.tblEL_Lessons l ON lp.LessonID = l.LessonID and l.IsDeleted = 0
			JOIN dbo.tblEL_AssignToClass atc ON atc.ResourceID = l.LessonID
				AND atc.ResourceType = 'LESSON' AND atc.IsDeleted = 0
			WHERE lp.HocSinhID = @HocSinhID
			  AND lp.IsCompleted = 1
			  AND lp.IsDeleted = 0
			  AND atc.MonHocLopID IN (
				  SELECT MonHocLopID FROM dbo.tblMonHocLop
				  WHERE NienKhoa = @NienKhoa
					AND LopNhomID IN (SELECT UnitID FROM @MyUnits)
			  )
			GROUP BY l.MonHocID  
		) t GROUP BY MonHocID
	)
    SELECT mh.Color, mh.Icon, mh.MonHocID, mh.MonHocName, 
           ISNULL(at.TotalCount, 0) AS TotalTasks, 
           ISNULL(ct.CompletedCount, 0) AS CompletedTasks,
		    0 AS OverdueTasks
    FROM dbo.tblMonHoc mh
    LEFT JOIN AllTasks at ON mh.MonHocID = at.MonHocID
    LEFT JOIN CompletedTasks ct ON mh.MonHocID = ct.MonHocID
    WHERE ISNULL(at.TotalCount, 0) > 0
    ORDER BY mh.Sort;
END
