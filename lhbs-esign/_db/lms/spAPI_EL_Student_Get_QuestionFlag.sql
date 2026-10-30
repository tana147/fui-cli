CREATE PROC [dbo].[spAPI_EL_Student_Get_QuestionFlag]
    @HocSinhID INT,
    @MonHocID  INT,
    @NienKhoa  INT
AS
BEGIN
    SET NOCOUNT ON;

    -- MonHocLop hợp lệ
    DECLARE @ValidMonHocLopIDs TABLE (MonHocLopID INT);
    INSERT INTO @ValidMonHocLopIDs
    SELECT MonHocLopID
    FROM dbo.tblMonHocLop
    WHERE NienKhoa = @NienKhoa
      AND MonHocID  = @MonHocID;

    -- ATC branch
    SELECT s.SubmissionID,
           s.AssignToClassID,
           s.AssignToStudentID,
           s.HocSinhID,
           s.SubmissionContent,
           s.SubmissionTime,
           s.SubmissionStatus,
           ISNULL(atc.AssignmentConfig, s.AssignmentConfig) AS AssignmentConfig,
           asm.Title AS AssignmentTitle,
           s.LanNop,
           s.Score,
           s.TeacherComment,
           s.GradedByTeacherID,
           s.GradedDate,
           s.IsOverDue
    FROM dbo.tblEL_Submissions s
    INNER JOIN dbo.tblEL_AssignToClass atc
        ON atc.AssignToClassID = s.AssignToClassID
       AND atc.IsDeleted       = 0
       AND atc.NienKhoa        = @NienKhoa
       AND atc.MonHocLopID    IN (SELECT MonHocLopID FROM @ValidMonHocLopIDs)
    LEFT JOIN dbo.tblEL_Assignments asm
        ON asm.AssignmentID = atc.AssignmentID
    WHERE s.IsDeleted  = 0
      AND s.HocSinhID  = @HocSinhID

    UNION

    -- ATS branch
    SELECT s.SubmissionID,
           s.AssignToClassID,
           s.AssignToStudentID,
           s.HocSinhID,
           s.SubmissionContent,
           s.SubmissionTime,
           s.SubmissionStatus,
           ISNULL( ats.AssignmentConfig,s.AssignmentConfig) AS AssignmentConfig,
           asm.Title AS AssignmentTitle,
           s.LanNop,
           s.Score,
           s.TeacherComment,
           s.GradedByTeacherID,
           s.GradedDate,
           s.IsOverDue
    FROM dbo.tblEL_Submissions s
    INNER JOIN dbo.tblEL_AssignToStudent ats
        ON ats.AssignToStudentID = s.AssignToStudentID
       AND ats.IsDeleted         = 0
       AND ats.NienKhoa          = @NienKhoa
       AND ats.MonHocLopID      IN (SELECT MonHocLopID FROM @ValidMonHocLopIDs)
    LEFT JOIN dbo.tblEL_Assignments asm
        ON asm.AssignmentID = ats.AssignmentID
    WHERE s.IsDeleted  = 0
      AND s.HocSinhID  = @HocSinhID;

END;