CREATE PROCEDURE [dbo].[spAPI_EL_Student_InsertSubmission]
    @AssignToClassID INT,
    @HocSinhID INT,
    @SubmissionContent NVARCHAR(MAX),
    @SubmissionStatus TINYINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    -- Submission mới không được copy snapshot của lần trước. Frontend sẽ tải lại
    -- pool gốc và tạo một snapshot mới theo cấu hình random của bài.
    DECLARE @AssignmentConfig NVARCHAR(MAX) = NULL;
    DECLARE @SubmissionID_Out BIGINT;
    DECLARE @LanNop INT = 1;
    DECLARE @CheckLanNop INT;

    SET @CheckLanNop = ISNULL((
        SELECT TOP 1 LanNop
        FROM dbo.tblEL_Submissions
        WHERE HocSinhID = @HocSinhID
          AND AssignToClassID = @AssignToClassID
          AND IsDeleted = 0
        ORDER BY LanNop DESC
    ), 0);

    IF @CheckLanNop >= ISNULL((
        SELECT LimitAssigned
        FROM dbo.tblEL_AssignToClass
        WHERE AssignToClassID = @AssignToClassID
          AND IsDeleted = 0
    ), 1)
    BEGIN
        RAISERROR(N'Đã đạt giới hạn số lần được phép làm lại', 16, 1);
        RETURN;
    END;

    SET @LanNop = @CheckLanNop + 1;

    DECLARE @Is_OverDue BIT = 0;
    DECLARE @Duedate DATETIME;
    SELECT @Duedate = DueDate
    FROM dbo.tblEL_AssignToClass
    WHERE AssignToClassID = @AssignToClassID
      AND IsDeleted = 0;
    IF @Duedate IS NOT NULL AND GETDATE() > @Duedate
        SET @Is_OverDue = 1;

    INSERT INTO dbo.tblEL_Submissions
    (
        AssignToClassID, HocSinhID, SubmissionContent, SubmissionStatus,
        SubmissionTime, CreateUser, CreateTime, IsOverDue, LanNop, AssignmentConfig
    )
    VALUES
    (
        @AssignToClassID, @HocSinhID, @SubmissionContent, @SubmissionStatus,
        CASE WHEN @SubmissionStatus >= 2 THEN GETDATE() ELSE NULL END,
        @sys_UserID, GETDATE(), @Is_OverDue, @LanNop, @AssignmentConfig
    );

    SELECT @SubmissionID_Out = CONVERT(BIGINT, SCOPE_IDENTITY());

    IF @SubmissionStatus >= 2 AND @SubmissionID_Out IS NOT NULL
    BEGIN
        DECLARE @CurrentTime DATETIME = GETDATE();
        INSERT INTO dbo.tblEL_Activity_Logs
        (HocSinhID, ActivityType, ResourceID, ResourceType, CreateUser, CreateTime)
        VALUES
        (@HocSinhID, 'SUBMISSION_NEW', @SubmissionID_Out, 'SUBMISSION', @sys_UserID, @CurrentTime);

        EXEC dbo.spAPI_EL_Log_NopBai_Ins
            @SubmissionID = @SubmissionID_Out,
            @SubmissionContent = @SubmissionContent,
            @SubmissionTime = @CurrentTime,
            @SYS_USERID = @HocSinhID;
    END;

    EXEC dbo.spAPI_EL_Student_GetAssignmentDetail
        @HocSinhID = @HocSinhID,
        @AssignToClassID = @AssignToClassID,
        @LanNop = @LanNop,
        @sys_UserID = @HocSinhID;
END