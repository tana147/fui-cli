CREATE PROC spAPI_Log_Submission_Ins
		@SubmissionID INT,
		@Is_QuaHan BIT,
		@Comment NVARCHAR(max),
		@TinhTrang INT,
		@SYS_USERID varchar(9)
	AS 
	BEGIN
		INSERT INTO Log_Submission(
			SubmissionID,
			Is_QuaHan,
			Comment,
			TinhTrang,
			CreateUser,
			CreateTime,
			Enable
		)
		VAlUES(
			@SubmissionID,
			@Is_QuaHan,
			@Comment,
			@TinhTrang,
			@SYS_USERID,
			GETDATE(),
			1
		)
	
	END