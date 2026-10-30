CREATE PROC [dbo].[spAPI_EL_Log_ChamBai_Ins_AssignToStudent]
    @SubmissionID      INT
  , @AssignToStudentID   INT
  , @AssignmentConfig  NVARCHAR(MAX)
  , @SubmissionContent NVARCHAR(MAX)
  , @SubmissionStatus  INT
  , @Reason            NVARCHAR(2000) = NULL
  , @SYS_USERID        VARCHAR(9)
AS
BEGIN

    DECLARE @Table TABLE
    (
        Log_ChamBaiID INT
    );
    INSERT INTO dbo.tblEL_Log_ChamBai
    (
        SubmissionID
      , AssignToStudentID
      , AssignmentConfig
      , SubmissionStatus
      , SubmissionContent
      , Reason
      , CreateUser
      , CreateTime
    )
    OUTPUT Inserted.Log_ChamBaiID
    INTO @Table
    VALUES
    (
        @SubmissionID      -- Log_ChamBaiID - int
      , @AssignToStudentID   -- AssignToClassID - int
      , @AssignmentConfig  -- AssignmentConfig - nvarchar(max)
      , @SubmissionStatus
      , @SubmissionContent -- SubmissionContent - nvarchar(max)
      , @Reason
      , @SYS_USERID        -- CreateUser - varchar(9)
      , GETDATE()          -- CreateTime - datetime
    );

    SELECT Log_ChamBaiID
    FROM
           @Table;
END;