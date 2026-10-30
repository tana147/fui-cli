CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_AssignToClasses]
    @AssignmentID INT,
    @JsonMonHocLopIDs NVARCHAR(MAX), -- '[7801, 7802, 7803]'
    @DueDate DATETIME,
    @MaxScore DECIMAL(5,2),
    @sys_UserID VARCHAR(9)
AS
BEGIN
	-- Đồng bộ identity với AssignToClasses_CLASS và các API teacher còn lại.
	SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID);

    -- Lấy AssignmentConfig từ đề gốc
    DECLARE @AssignmentConfig_Original NVARCHAR(MAX);
    DECLARE @AssignmentConfig_Original_NoAnswer NVARCHAR(MAX);
    SELECT @AssignmentConfig_Original = AssignmentConfig,
           @AssignmentConfig_Original_NoAnswer = AssignmentConfig_NoAnswer
    FROM tblEL_Assignments
    WHERE AssignmentID = @AssignmentID;

    -- Dùng MERGE để chèn hoặc cập nhật bản ghi giao bài
    MERGE dbo.tblEL_AssignToClass AS target
    USING (
        SELECT CAST(value AS INT) AS MonHocLopID FROM OPENJSON(@JsonMonHocLopIDs)
    ) AS source
    ON (target.AssignmentID = @AssignmentID AND target.MonHocLopID = source.MonHocLopID)
    WHEN MATCHED THEN
        UPDATE SET 
            DueDate = @DueDate,
            MaxScore = @MaxScore,
            AssignmentConfig = @AssignmentConfig_Original,
            AssignmentConfig_NoAnswer = @AssignmentConfig_Original_NoAnswer,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID,
            IsDeleted = 0
    WHEN NOT MATCHED THEN
        INSERT (AssignmentID, MonHocLopID, AssignmentConfig, AssignmentConfig_NoAnswer, DueDate, MaxScore, ResourceID, CreateUser,LimitAssigned)
        VALUES (@AssignmentID, source.MonHocLopID, @AssignmentConfig_Original, @AssignmentConfig_Original_NoAnswer, @DueDate, @MaxScore, @AssignmentID, @sys_UserID,1);

    SELECT Success = 1, Message = N'Đã giao bài thành công.';
END
