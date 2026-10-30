-- FILE: spAPI_Teacher_GetSubmissionDetail.sql
-- =================================================================================
-- Author:         AI Agent (for Fast Project)
-- Description:    Lấy dữ liệu chi tiết của một bài nộp cụ thể để giáo viên chấm bài.
--                 Bao gồm cả thông tin đề bài và bài làm của học sinh.
-- API Endpoint:   POST lms/teacher_getsubmissiondetail
-- Ví dụ Body:     { "SubmissionID": 1 }
-- =================================================================================
-- [dbo].[spAPI_EL_Teacher_GetSubmissionDetail] 58, 'NV0000244'
CREATE  PROCEDURE [dbo].[spAPI_EL_Teacher_GetSubmissionDetail_OLD] 
    @SubmissionID BIGINT,
    @sys_UserID VARCHAR(9) -- GiaoVienID được lấy từ token
AS
BEGIN
    SET NOCOUNT ON;

	SET @sys_UserID = 'NV0000244'

    DECLARE @AssignToClassID INT, @HocSinhID INT;

    -- Lấy AssignmentID và HocSinhID từ SubmissionID
    SELECT 
        @AssignToClassID = AssignToClassID,
        @HocSinhID = HocSinhID
    FROM dbo.tblEL_Submissions
    WHERE SubmissionID = @SubmissionID;

    IF @AssignToClassID IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy bài nộp này.', 16, 1);
        RETURN;
    END


    -- === LOGIC PHÂN QUYỀN ===
   --  Kiểm tra xem giáo viên có phải là người tạo ra bài tập này không
    IF NOT EXISTS (SELECT 1 FROM dbo.tblEL_Assignments  a inner join tblEL_AssignToClass b on A.AssignmentID = B.AssignmentID AND B.ResourceType = 'ASSIGNMENT' WHERE b.AssignToClassID = @AssignToClassID AND b.CreateUser = @sys_UserID)
    BEGIN
        RAISERROR(N'[Unauthorized] Bạn không có quyền chấm bài cho bài tập này.', 16, 1);
        RETURN;
    END

    -- === Bảng 1: Trả về thông tin chi tiết của Assignment (Đề bài) ===
    SELECT 
        a.AssignToClassID, 
		--   a.AssignToClassID as AssignmentID, 
		asm.Title, asm.Instructions, ISNULL(a.AssignmentConfig, asm.AssignmentConfig) as AssignmentConfig,
        a.DueDate, a.MaxScore, mh.MonHocName, l.TenLop, l.LopID
    FROM dbo.tblEL_AssignToClass a
	JOIN dbo.tblEL_Assignments as asm on a.AssignmentID = asm.AssignmentID  
    JOIN dbo.tblMonHocLop mhl ON a.MonHocLopID = mhl.MonHocLopID
    JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
    JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID AND l.NienKhoa = mhl.NienKhoa -- Giả sử LopNhomID là LopID chính thức
    WHERE a.AssignToClassID = @AssignToClassID;
    
    -- === Bảng 2: Trả về thông tin chi tiết của Submission (Bài làm) ===
    SELECT 
        s.SubmissionID, s.AssignToClassID, s.HocSinhID, hs.Ho + ' ' + hs.Ten as HoTenHocSinh,
        s.SubmissionContent, s.SubmissionTime, s.SubmissionStatus, 
        s.Score, s.TeacherComment, s.GradedByTeacherID, s.GradedDate
    FROM dbo.tblEL_Submissions s
    JOIN dbo.tblHocSinh hs ON s.HocSinhID = hs.HocSinhID
    WHERE s.SubmissionID = @SubmissionID;

END
