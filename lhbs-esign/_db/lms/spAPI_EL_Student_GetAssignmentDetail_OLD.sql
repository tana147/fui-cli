CREATE PROCEDURE [dbo].[spAPI_EL_Student_GetAssignmentDetail_OLD] --1, 'NA0000022'
    @AssignToClassID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MonHocLopID INT;
	DECLARE @HocSinhID INT = CAST(RIGHT(@sys_UserID,8) AS INT);
    IF @AssignToClassID IS NULL
    BEGIN
        RAISERROR(N'[Unauthorized] Bạn không được giao bài tập này.', 16, 1);
        RETURN;
    END
	    

    -- === Bảng 1: Thông tin Assignment (Đề bài) ===
    -- Lấy thông tin từ cả 2 bảng: đề gốc (Assignments) và thông tin giao bài (AssignToClass)
    SELECT 
        atc.AssignmentID,
        asm.Title,
        asm.Instructions,
        atc.AssignmentConfig,
        atc.DueDate,          -- Lấy hạn nộp từ bảng giao bài
        atc.MaxScore,         -- Lấy điểm tối đa từ bảng giao bài
        mh.MonHocName,
        AssignToClassID,
		KhoiID,
		asm.MonHocID
    FROM dbo.tblEL_AssignToClass as atc
		INNER JOIN dbo.tblEL_Assignments as asm ON asm.AssignmentID = atc.AssignmentID
		INNER JOIN dbo.tblMonHocLop mhl ON atc.MonHocLopID = mhl.MonHocLopID
		INNER JOIN dbo.tblMonHoc mh ON asm.MonHocID = mh.MonHocID -- Lấy MonHocID từ đề gốc
    WHERE atc.AssignToClassID = @AssignToClassID 
    
    -- === Bảng 2: Thông tin Submission (Bài làm) ===
    -- Lấy bài nộp dựa trên AssignToClassID để đảm bảo tính duy nhất
    SELECT top 1
        SubmissionID, 
        SubmissionContent, 
        SubmissionStatus, 
        Score, 
        TeacherComment, 
        GradedDate, 
        GradedByTeacherID
    FROM dbo.tblEL_Submissions 
    WHERE AssignToClassID = @AssignToClassID AND HocSinhID = @HocSinhID
END