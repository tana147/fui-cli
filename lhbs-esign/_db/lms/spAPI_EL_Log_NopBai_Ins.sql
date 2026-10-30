CREATE PROC spAPI_EL_Log_NopBai_Ins
    @SubmissionID      INT
  , @SubmissionContent NVARCHAR(MAX)
  , @SubmissionTime    DATETIME
  , @SYS_USERID        VARCHAR(9)
AS
BEGIN
    INSERT INTO dbo.tblEL_Log_NopBai
    (
        SubmissionID
      , SubmissionContent
      , SubmissionTime
      , CreateUser
      , CreateTime
    )
    VALUES
    (
        @SubmissionID      -- Log_ChamBaiID - int
      , @SubmissionContent -- AssignToClassID - int
      , @SubmissionTime    -- SubmissionContent - nvarchar(max)
      , @SYS_USERID        -- CreateUser - varchar(9)
      , GETDATE()          -- CreateTime - datetime
    );
END;