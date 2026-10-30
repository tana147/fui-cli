CREATE PROCEDURE [dbo].[spAPI_EL_Student_InsertSubmission_AssignToStudent]
    @AssignToStudentID INT,
    @HocSinhID INT,
    @SubmissionContent NVARCHAR(MAX),
    @SubmissionStatus TINYINT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM dbo.tblEL_AssignToStudent
        WHERE AssignToStudentID = @AssignToStudentID
          AND HocSinhID = @HocSinhID
          AND IsDeleted = 0
    )
    BEGIN
        RAISERROR(N'Không tìm thấy thông tin giao bài.', 16, 1);
        RETURN;
    END;

    DECLARE @LimitAssigned INT;
    DECLARE @DueDate DATETIME;
    SELECT
        @LimitAssigned = ISNULL(LimitAssigned, 1),
        @DueDate = DueDate
    FROM dbo.tblEL_AssignToStudent
    WHERE AssignToStudentID = @AssignToStudentID
      AND HocSinhID = @HocSinhID
      AND IsDeleted = 0;

    DECLARE @LastLanNop INT = ISNULL((
        SELECT MAX(ISNULL(LanNop, 1))
        FROM dbo.tblEL_Submissions
        WHERE AssignToStudentID = @AssignToStudentID
          AND HocSinhID = @HocSinhID
          AND IsDeleted = 0
    ), 0);

    IF @LastLanNop >= @LimitAssigned
    BEGIN
        RAISERROR(N'Đã đạt giới hạn số lần được phép làm lại', 16, 1);
        RETURN;
    END;

    DECLARE @LanNop INT = @LastLanNop + 1;
    DECLARE @IsOverDue BIT = CASE WHEN @DueDate IS NOT NULL AND GETDATE() > @DueDate THEN 1 ELSE 0 END;

    -- Không copy AssignmentConfig của lần trước. Snapshot đề sẽ được tạo lại
    -- khi attempt mới được tải, theo pool và số câu giáo viên đã cấu hình.
    INSERT INTO dbo.tblEL_Submissions
    (
        AssignToClassID,
        AssignToStudentID,
        HocSinhID,
        SubmissionContent,
        SubmissionStatus,
        SubmissionTime,
        CreateUser,
        CreateTime,
        IsOverDue,
        LanNop,
        AssignmentConfig
    )
    VALUES
    (
        -1,
        @AssignToStudentID,
        @HocSinhID,
        @SubmissionContent,
        @SubmissionStatus,
        CASE WHEN @SubmissionStatus >= 2 THEN GETDATE() ELSE NULL END,
        @sys_UserID,
        GETDATE(),
        @IsOverDue,
        @LanNop,
        NULL
    );

    EXEC dbo.spAPI_EL_Student_GetAssignmentDetail_AssignToStudent
        @AssignToStudentID = @AssignToStudentID,
        @HocSinhID = @HocSinhID,
        @LanNop = @LanNop,
        @sys_UserID = @sys_UserID;
END