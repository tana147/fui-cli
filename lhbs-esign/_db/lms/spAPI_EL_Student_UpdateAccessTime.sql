CREATE PROCEDURE [dbo].[spAPI_EL_Student_UpdateAccessTime]
		@SubmissionID INT,
		@Sys_UserID varchar(9)
AS
BEGIN
	DECLARE @SubmissionStatus INT
	SET @SubmissionStatus = (SELECT SubmissionStatus FROM tblEL_Submissions WHERE SubmissionID = @SubmissionID)

	DECLARE @HocSinhID varchar(9)
	SET @HocSinhID = CAST((SELECT HocSinhID FROM tblEL_Submissions WHERE SubmissionID = @SubmissionID) AS varchar(9))

	IF(@SubmissionStatus in (2,3,4))
	BEGIN
		RAISERROR(N'Trạng thái bài tập không hợp lệ!', 16, 1);
		RETURN;
	END

	-- Nếu không phải học sinh của bài và cũng không phải user bắt đầu bằng P
	IF(@Sys_UserID <> @HocSinhID AND LEFT(@Sys_UserID,1) <> 'P' AND LEFT(@Sys_UserID,2) <> 'NV')
	BEGIN
		RAISERROR(N'[Unauthorized] Bạn không có quyền truy cập bài tập này.', 16, 1);
		RETURN;
	END

	UPDATE tblEL_Submissions
	SET AccessTime = ISNULL(AccessTime,0) + 1
	WHERE SubmissionID = @SubmissionID
END