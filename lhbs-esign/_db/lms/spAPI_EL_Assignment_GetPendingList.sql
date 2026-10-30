-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Create date:    [Ngày hiện tại]
-- Description:    Lấy danh sách các bài tập đang chờ chấm cho giáo viên đăng nhập.
--                 Mỗi dòng kết quả là một assignment có ít nhất một bài nộp
--                 đang ở trạng thái "Đã nộp" và "Chưa có điểm".
-- API Endpoint:   GET lms/EL_Assignment_GetPendingGrading
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Assignment_GetPendingList] --'NA0000022'
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

	DECLARE @classCount			INT		= 0 
	DECLARE @lessonCount		INT	= 0
	DECLARE @pendingAssignments INT	= 0
	DECLARE @activeStudents		INT	= 0

	select @classCount = COUNT(*)
	from tblGiaoVienLop 
	where GiaoVienID = @sys_UserID and Enable = 1

	SELECT @lessonCount = COUNT(*) 
	FROM tblEL_AssignToClass atc 
	where atc.CreateUser = @sys_UserID and atc.IsDeleted = 0

	select @pendingAssignments = COUNT(*)
	from tblEL_AssignToClass as atc
	where atc.DueDate <= GETDATE()

	select 
		convert_to_object = '',
			@classCount			 as classCount			 ,
			@lessonCount		 as lessonCount		 ,
			@pendingAssignments  as pendingAssignments  ,
			@activeStudents		 as activeStudents		 

  --  -- Sử dụng CTE để nhóm và đếm số bài nộp cần chấm cho mỗi bài tập
  --  WITH PendingSubmissions AS (
  --      SELECT
  --          s.AssignToClassID,
  --          COUNT(s.SubmissionID) AS PendingCount
  --      FROM 
  --          dbo.tblEL_Submissions s
  --      WHERE
  --          s.IsDeleted = 0
  --          AND s.SubmissionStatus = 2 -- Trạng thái: Đã nộp
  --          AND s.Score IS NULL        -- Chưa được chấm điểm
  --      GROUP BY
  --          s.AssignmentID
  --  )
  --  -- Lấy thông tin chi tiết của các bài tập có bài nộp đang chờ
  --  SELECT 
  --      a.AssignToClassID,
  --      a.Title,
  --      a.DueDate,
  --      mhl.MonHocLopID,
  --      mh.MonHocName,
  --      -- Lấy danh sách các lớp được giao bài tập này
  --      STUFF(
  --          (
  --              SELECT ', ' + l.TenLop
  --              FROM tblEL_AssignToClass atc
  --              JOIN tblLop l ON atc.LopID = l.LopID
  --              WHERE atc.ResourceType = 'ASSIGNMENT' AND atc.ResourceID = a.AssignmentID AND atc.IsDeleted = 0
  --              FOR XML PATH('')
  --          ), 1, 2, ''
  --      ) AS AssignedClasses,
  --      ps.PendingCount
  --  FROM 
  --      dbo.tblEL_AssignToClass a
		--inner join tblEL_Assignments as asm on asm.AssignmentID = a.AssignmentID and asm.IsDeleted = 0
  --  INNER JOIN 
  --      PendingSubmissions ps ON a.AssignmentID = ps.AssignmentID
  --  INNER JOIN 
  --      dbo.tblMonHocLop mhl ON a.MonHocLopID = mhl.MonHocLopID
  --  INNER JOIN 
  --      dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
  --  WHERE
  --      (@sys_UserID ='NA0000022' OR a.CreateUser = @sys_UserID )-- Chỉ lấy bài tập của giáo viên này
  --      AND a.IsDeleted = 0
  --      AND a.Status = 2 -- Chỉ lấy bài tập đã Published
  --  ORDER BY
  --      a.DueDate ASC; -- Sắp xếp theo hạn nộp, bài nào sắp hết hạn lên đầu
END
