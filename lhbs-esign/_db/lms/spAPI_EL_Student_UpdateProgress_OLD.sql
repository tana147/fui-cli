
-- =================================================================================
-- Description:    Cập nhật tiến độ học của học sinh.
--                 API PUBLIC, cần truyền HocSinhID.
-- API Endpoint:   POST lms/auth/el_student_updateprogress
-- =================================================================================
CREATE PROCEDURE [dbo].[spAPI_EL_Student_UpdateProgress_OLD]
    --@HocSinhID INT,
    @LessonID INT,
    @TimeSpentSeconds INT,
    @IsCompleted BIT,
	@SYS_USERID VARCHAR(9)
AS
BEGIN
	DECLARE  @HocSinhID VARCHAR(9) 
	SET @HocSinhID = CAST(RIGHT(@sys_UserID,8) AS INT);


    MERGE dbo.tblEL_Learning_Progress AS target
    USING (SELECT @LessonID as LessonID, @HocSinhID as HocSinhID) AS source
    ON (target.LessonID = source.LessonID AND target.HocSinhID = source.HocSinhID)
    WHEN MATCHED THEN
        UPDATE SET 
            TimeSpentSeconds = ISNULL(target.TimeSpentSeconds, 0) + @TimeSpentSeconds,
            IsCompleted = CASE 
				WHEN ISNULL(target.TimeSpentSeconds, 0) >= 180 THEN 1
				ELSE 0
			END , --@IsCompleted
            CompletedDate = CASE WHEN @IsCompleted = 1 AND target.CompletedDate IS NULL THEN GETDATE() ELSE target.CompletedDate END,
            LastAccessed = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (HocSinhID, LessonID, TimeSpentSeconds, IsCompleted, CompletedDate, LastAccessed)
        VALUES (@HocSinhID, @LessonID, @TimeSpentSeconds, @IsCompleted, 
                CASE WHEN @IsCompleted = 1 THEN GETDATE() ELSE NULL END, GETDATE());
END
