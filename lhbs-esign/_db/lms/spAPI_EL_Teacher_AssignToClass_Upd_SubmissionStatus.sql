CREATE PROCEDURE spAPI_EL_Teacher_AssignToClass_Upd_SubmissionStatus
	@SubmissionID INT,
	@SubmissionStatus INT
	AS
	BEGIN
		-- Không cho phép đổi sang Đã chấm nếu bản ghi chưa có điểm tổng.
		IF @SubmissionStatus = 4
		   AND EXISTS (
				SELECT 1
				FROM tblEL_Submissions
				WHERE SubmissionID = @SubmissionID
				  AND Score IS NULL
			)
		BEGIN
			RAISERROR(N'Không thể chuyển trạng thái đã chấm khi Score bị thiếu.', 16, 1);
			RETURN;
		END;

		UPDATE tblEL_Submissions
		SET SubmissionStatus = @SubmissionStatus
		WHERE SubmissionID = @SubmissionID
	END
