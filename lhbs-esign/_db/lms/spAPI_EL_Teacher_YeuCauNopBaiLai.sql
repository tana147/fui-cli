CREATE PROC [dbo].[spAPI_EL_Teacher_YeuCauNopBaiLai]
    @SubmissionID INT
  , @Reason       NVARCHAR(2000)
  , @SYS_USERID   VARCHAR(9)
AS
BEGIN

    DECLARE @HocSinhID INT;
    DECLARE @AssignToClassID INT;
    DECLARE @SubmissionContent NVARCHAR(MAX);
    DECLARE @AssignmentConfig NVARCHAR(MAX);

    DECLARE @Table_LogID TABLE
    (
        Log_ChamBaiID INT
    );
    DECLARE @Log_ChamBaiID INT;


    SELECT @HocSinhID         = HocSinhID
         , @AssignToClassID   = AssignToClassID
         , @SubmissionContent = SubmissionContent
    FROM
           dbo.tblEL_Submissions
    WHERE
           SubmissionID = @SubmissionID;

    SELECT @AssignmentConfig = AssignmentConfig
    FROM
           dbo.tblEL_AssignToClass
    WHERE
           AssignToClassID = @AssignToClassID;

    INSERT INTO @Table_LogID
    EXEC dbo.spAPI_EL_Log_ChamBai_Ins @SubmissionID = @SubmissionID           -- int
                                    , @AssignToClassID = @AssignToClassID     -- int
                                    , @AssignmentConfig = @AssignmentConfig   -- nvarchar(max)
                                    , @SubmissionContent = @SubmissionContent -- nvarchar(max)
                                    , @SubmissionStatus = 0                   -- int
                                    , @Reason = @Reason
                                    , @SYS_USERID = @SYS_USERID;              -- varchar(9)

    UPDATE dbo.tblEL_Submissions
    SET    Log_ChamBaiID =
           (
               SELECT TOP 1
                      Log_ChamBaiID
               FROM
                      @Table_LogID
           )
         , SubmissionStatus = 0
         , UpdateTime = GETDATE()
         , UpdateUser = @SYS_USERID
    WHERE
           SubmissionID = @SubmissionID;

    --Gắn thêm thông báo
    EXEC [dbo].[spAPI_ThongBao_Ins] @ResourceID = @SubmissionID
                                  , @ResourceType = 'SUBMISSION'
                                  , @ThongBao_TemplateID = 9
                                  , @NguoiNhan = @HocSinhID
                                  , @SYS_USERID = @SYS_USERID;
END;