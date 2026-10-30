CREATE PROCEDURE [dbo].[spAPI_EL_Student_SaveSubmission_AssignToStudent_WithFlag]
    @AssignToStudentID   INT
  , @HocSinhID         INT
  , @SubmissionContent NVARCHAR(MAX)
  , @sys_UserID        VARCHAR(9)
AS
BEGIN

    DECLARE @SubmissionID INT = 0;
    SELECT @SubmissionID = SubmissionID
    FROM
           dbo.tblEL_Submissions
    WHERE
           HocSinhID      = @HocSinhID
      AND  AssignToStudentID = @AssignToStudentID
      AND  IsDeleted       = 0;

    UPDATE dbo.tblEL_Submissions
    SET    SubmissionContent = @SubmissionContent
         , UpdateTime = GETDATE()
         , UpdateUser = @HocSinhID
    WHERE
           SubmissionID = @SubmissionID;
END;
 