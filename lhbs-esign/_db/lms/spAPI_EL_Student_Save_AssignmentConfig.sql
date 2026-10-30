CREATE PROCEDURE spAPI_EL_Student_Save_AssignmentConfig
	@SubmissionID int,
	@AssignmentConfig nvarchar(max),
	@SYS_USERID varchar(9)
as
begin
	-- AssignmentConfig is the immutable question-set snapshot for this submission.
	-- Normal assignments keep the full configured set. RANDOM pool assignments store
	-- only the questions selected for this attempt; reporting must derive/use that
	-- attempt's denominator, never the source pool's MaxScore.
	DECLARE @AttemptMaxScore DECIMAL(10, 2) = NULL;

	-- Only RANDOM pool attempts own a separate denominator. A normal assignment
	-- deliberately keeps NULL and reporting falls back to the assignment MaxScore.
	IF ISJSON(@AssignmentConfig) = 1
	   AND EXISTS
	   (
	       SELECT 1
	       FROM OPENJSON(@AssignmentConfig, '$.groups') AS randomGroup
	       WHERE JSON_VALUE(randomGroup.value, '$.questionSelection.mode') = 'RANDOM'
	   )
	BEGIN
		SELECT @AttemptMaxScore = SUM(ISNULL(q.Points, 1.00))
		FROM OPENJSON(@AssignmentConfig, '$.groups') AS groups
		CROSS APPLY OPENJSON(groups.value, '$.questions')
			WITH (Points DECIMAL(10, 2) '$.points') AS q;
	END;

	UPDATE dbo.tblEL_Submissions
		SET AssignmentConfig = @AssignmentConfig,
			AttemptMaxScore = @AttemptMaxScore
	WHERE SubmissionID = @SubmissionID
end
