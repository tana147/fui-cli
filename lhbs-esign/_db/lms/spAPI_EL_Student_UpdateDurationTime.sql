CREATE PROCEDURE [dbo].[spAPI_EL_Student_UpdateDurationTime]
		@SubmissionID INT,
		@Sys_UserID varchar(9)
AS
BEGIN
	DECLARE @SubmissionStatus INT
	SET @SubmissionStatus = (SELECT  SubmissionStatus FROM tblEL_Submissions WHERE SubmissionID =@SubmissionID)

	DECLARE @HocSinhID varchar(9)
	SET @HocSinhID = CAST((SELECT HocSinhID FROM tblEL_Submissions WHERE SubmissionID =@SubmissionID) AS varchar(9))

	IF(@SubmissionStatus in (2,3,4))
	BEGIN
		 RAISERROR(N'Trạng thái bài tập không hợp lệ!', 16, 1);
        RETURN;
	END
IF(@Sys_UserID <> @HocSinhID AND LEFT(@Sys_UserID,1) <> 'P' AND LEFT(@Sys_UserID,2) <> 'NV')
	BEGIN
		RAISERROR(N'[Unauthorized] Bạn không có quyền truy cập bài tập này.', 16, 1);
		RETURN;
	END

	UPDATE tblEL_Submissions
		SET DurationTime = ISNULL(DurationTime,0) + 5
	WHERE SubmissionID = @SubmissionID
END