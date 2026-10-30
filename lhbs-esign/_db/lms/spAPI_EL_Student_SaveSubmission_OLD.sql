
-- =================================================================================
-- Description:    Lưu nháp hoặc nộp bài làm của học sinh.
--                 API PUBLIC.
-- API Endpoint:   POST lms/auth/el_student_savesubmission
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_SaveSubmission_OLD]
    @AssignToClassID INT,
    @HocSinhID INT,
    @SubmissionContent NVARCHAR(MAX),
    @SubmissionStatus TINYINT, -- 1: Draft, 2: Submitted
	@Sys_UserID VARCHAR(9)
AS
BEGIN
	
	IF @HocSinhID  > 0
		set @Sys_UserID = @HocSinhID

    MERGE dbo.tblEL_Submissions AS target
    USING (SELECT @AssignToClassID as AssignToClassID, @Sys_UserID as HocSinhID) AS source
    ON (target.AssignToClassID = source.AssignToClassID AND target.HocSinhID = source.HocSinhID)
    WHEN MATCHED AND target.SubmissionStatus != 2 THEN -- Chỉ cho phép update nếu chưa nộp
        UPDATE SET
            SubmissionContent = @SubmissionContent,
            SubmissionStatus = @SubmissionStatus,
            SubmissionTime = CASE WHEN @SubmissionStatus = 2 THEN GETDATE() ELSE target.SubmissionTime END,
            UpdateTime = GETDATE(),
            UpdateUser = @SYS_USERID
    WHEN NOT MATCHED THEN
        INSERT (AssignToClassID, HocSinhID, SubmissionContent, SubmissionStatus, SubmissionTime,
		CreateUser, CreateTime)
        VALUES (@AssignToClassID, @Sys_UserID, @SubmissionContent, @SubmissionStatus, 
                CASE WHEN @SubmissionStatus = 2 THEN GETDATE() ELSE NULL END,
				@Sys_UserID, GETDATE());
	
	--Lấy lại dữ liệu để load lại UI
	 EXEC spAPI_EL_Student_GetAssignmentDetail  
		@AssignToClassID = @AssignToClassID,
		@Sys_UserID = @Sys_UserID
END
