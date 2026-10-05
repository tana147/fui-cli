CREATE FUNCTION [dbo].[CheckStatusFlow] 
(
	@Student_ID varchar(20),
	@Process_ID int, 
	@Flow_ID	int,
	@Task_ID	int,
	@Task_Begin	int
)
RETURNS varchar(20)
AS
BEGIN
	DECLARE @SUM_CHILD_FLOW_UN_COMPLETED int, @CNT_CHILD_FLOW_PROCESSING int;
	DECLARE @SUM_FLOW_UN_COMPLETED int, @CNT_FLOW_PROCESSING int;
	DECLARE @NOW_STATUS varchar(20);
	if(@Task_Begin = @Task_ID)
		select @NOW_STATUS = ISNULL(MAX(Process_Student_Status),' ') from Process_student where Process_ID = @Process_ID and Student_ID =@Student_ID AND USE_YN = 1;
	else
		select @NOW_STATUS = ISNULL(MAX(FLOW_STATUS),' ') from FLOW where Process_ID = @Process_ID and Task_ID = @Task_ID and Student_ID =@Student_ID AND USE_YN = 1;
	if(@NOW_STATUS = ' ')
		return @NOW_STATUS;
	--GET STATUS CHILD NODE
	SELECT @SUM_CHILD_FLOW_UN_COMPLETED = isnull(SUM(CASE WHEN TASK_REQUIRE = 1 THEN CASE WHEN FLOW_STATUS <> 'C' THEN 1 ELSE 0 END
													ELSE CASE WHEN FLOW_STATUS ='W' THEN 0 ELSE 1 END
												END),0),
			@CNT_CHILD_FLOW_PROCESSING= isnull(SUM(CASE WHEN FLOW_STATUS IN('R','P','C') THEN 1 ELSE 0 END),0)
	FROM FLOW 
	WHERE Task_Parent = @Task_ID AND Process_ID = @Process_ID and STUDENT_ID = @Student_ID  AND USE_YN = 1
	; 
						
	--GET FLOW STATUS
	if(@Task_Begin = @Task_ID)
	begin
		set @SUM_FLOW_UN_COMPLETED=0;
		set @CNT_FLOW_PROCESSING = 0;
	end
	else
	begin
		SELECT  @SUM_FLOW_UN_COMPLETED= SUM(CASE WHEN FLOW_DETAIL_STATUS<>'C' THEN 1 ELSE 0 END), 
				@CNT_FLOW_PROCESSING =SUM(CASE WHEN FLOW_DETAIL_STATUS IN('R','P','C') THEN 1 ELSE 0 END)
		FROM FLOW_DETAIL
		WHERE Flow_ID=@Flow_ID AND TASK_ID = @Task_ID;

		if(@SUM_FLOW_UN_COMPLETED is null)
			return ' ';
	end
	if(@SUM_CHILD_FLOW_UN_COMPLETED=0 and @SUM_FLOW_UN_COMPLETED=0)
		return 'C';
	else
		if(@CNT_CHILD_FLOW_PROCESSING>0 or @CNT_FLOW_PROCESSING>0)
			return 'P';
		else
			if(@NOW_STATUS in('P','C'))
				return 'W'
	return @NOW_STATUS;
END
