CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_SaveGradeDraft]
    @SubmissionID BIGINT,
    @Score DECIMAL(5, 2),
    @TeacherComment NVARCHAR(MAX),
    @SubmissionContent NVARCHAR(MAX),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)

	-- Chấm lại bài đã trả (status 4) phải cập nhật điểm nhưng không hạ bài
	-- về nháp; các bài đang chấm vẫn đi theo luồng status 3 như trước.
	DECLARE @CurrentSubmissionStatus INT;
	DECLARE @SavedSubmissionStatus INT;
	SELECT @CurrentSubmissionStatus = SubmissionStatus
	FROM dbo.tblEL_Submissions
	WHERE SubmissionID = @SubmissionID;
	SET @SavedSubmissionStatus = CASE WHEN @CurrentSubmissionStatus = 4 THEN 4 ELSE 3 END;

    UPDATE dbo.tblEL_Submissions
    SET
        Score = @Score,
        TeacherComment = @TeacherComment,
        SubmissionContent = @SubmissionContent,
		SubmissionStatus = @SavedSubmissionStatus,
        UpdateUser = @sys_UserID,
        UpdateTime = GETDATE()
    WHERE SubmissionID = @SubmissionID;

	-- Lưu log đúng loại giao bài và đúng snapshot của submission.
	-- API cũ chỉ đọc AssignToClassID nên submission giao riêng cho học sinh
	-- bị log với ID lớp NULL và cấu hình pool gốc.
	DECLARE @AssignToClassID BIGINT;
    DECLARE @AssignToStudentID BIGINT;
    DECLARE @AssignmentConfig NVARCHAR(MAX);

    SELECT @AssignToClassID = s.AssignToClassID
         , @AssignToStudentID = s.AssignToStudentID
         , @AssignmentConfig = NULLIF(LTRIM(RTRIM(s.AssignmentConfig)), '')
    FROM dbo.tblEL_Submissions s
    WHERE s.SubmissionID = @SubmissionID;

    IF @AssignmentConfig IS NULL AND @AssignToClassID IS NOT NULL
    BEGIN
        SELECT @AssignmentConfig = atc.AssignmentConfig
        FROM dbo.tblEL_AssignToClass atc
        WHERE atc.AssignToClassID = @AssignToClassID;
    END;

    IF @AssignmentConfig IS NULL AND @AssignToStudentID IS NOT NULL
    BEGIN
        SELECT @AssignmentConfig = ats.AssignmentConfig
        FROM dbo.tblEL_AssignToStudent ats
        WHERE ats.AssignToStudentID = @AssignToStudentID;
    END;

    IF @AssignToClassID IS NOT NULL
    BEGIN
        EXEC spAPI_EL_Log_ChamBai_Ins
			@SubmissionID = @SubmissionID,
			@AssignToClassID = @AssignToClassID,
			@AssignmentConfig = @AssignmentConfig,
			@SubmissionContent = @SubmissionContent,
			@SubmissionStatus = @SavedSubmissionStatus,
			@SYS_USERID = @sys_UserID;
    END
    ELSE IF @AssignToStudentID IS NOT NULL
    BEGIN
        EXEC spAPI_EL_Log_ChamBai_Ins_AssignToStudent
			@SubmissionID = @SubmissionID,
			@AssignToStudentID = @AssignToStudentID,
			@AssignmentConfig = @AssignmentConfig,
			@SubmissionContent = @SubmissionContent,
			@SubmissionStatus = @SavedSubmissionStatus,
			@SYS_USERID = @sys_UserID;
    END;

    -- Bài đã trả có thể được giáo viên chấm lại và tự lưu bằng API nháp.
    -- Đồng bộ analytics theo điểm giáo viên để thống kê không giữ điểm tự chấm cũ.
    IF @CurrentSubmissionStatus = 4 AND ISJSON(@SubmissionContent) = 1
    BEGIN
        UPDATE ar
        SET ar.Score = TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(answer.value, '$.grading.manualScore')),
            ar.IsCorrect = CASE
                WHEN TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(answer.value, '$.grading.manualScore')) = ar.MaxScore THEN 1
                WHEN TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(answer.value, '$.grading.manualScore')) = 0 THEN 0
                ELSE NULL
            END
        FROM dbo.tblEL_Analytics_QuestionResults AS ar
        JOIN OPENJSON(@SubmissionContent, '$.answers') AS answer
          ON ar.QuestionID_InJSON COLLATE DATABASE_DEFAULT = answer.[key] COLLATE DATABASE_DEFAULT
        WHERE ar.SubmissionID = @SubmissionID
          AND ar.IsDeleted = 0
          AND JSON_VALUE(answer.value, '$.grading.manualScoreSource') = 'teacher_regrade'
          AND TRY_CONVERT(DECIMAL(5, 2), JSON_VALUE(answer.value, '$.grading.manualScore')) IS NOT NULL;
    END;

    -- Trả về dữ liệu đã cập nhật để đồng bộ UI
    SELECT * FROM dbo.tblEL_Submissions WHERE SubmissionID = @SubmissionID;
END
