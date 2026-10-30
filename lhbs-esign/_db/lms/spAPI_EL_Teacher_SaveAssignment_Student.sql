CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_SaveAssignment_Student]
    @AssignmentID INT = 0,
	@AssignToStudentID INT = 0,
    @MonHocID INT,
    @KhoiID INT,
    @Title NVARCHAR(255),
    @Instructions NVARCHAR(MAX),
    @AssignmentConfig NVARCHAR(MAX),
    @AssignmentConfig_NoAnswer NVARCHAR(MAX),
	@MaxScore float,
    @NienKhoa INT,
    @HocKi TINYINT,
	@IsBlockCopy_Paste BIT,
	@Is_Full_Quiz bit,
    @sys_UserID VARCHAR(9)
AS
BEGIN
	SET @sys_UserID = dbo.fn_GetUser_LMS(@sys_UserID)
    IF ISJSON(@AssignmentConfig) = 0 BEGIN RAISERROR('AssignmentConfig is not a valid JSON.', 16, 1); RETURN; END

	--Kiểm tra @AssignToStudentID có chưa?
	--Nếu có thì thì update vô bảng AssignToClass
	--Còn không thì về bảng Assignment
	IF (@AssignToStudentID > 0)
	BEGIN 
		 UPDATE dbo.tblEL_AssignToStudent
		 set
			AssignmentConfig = @AssignmentConfig,
			AssignmentConfig_NoAnswer = @AssignmentConfig_NoAnswer, 
			MaxScore = @MaxScore,
			UpdateUser = @sys_UserID,
			UpdateTime = GETDATE(),
			Is_Full_Quiz = @Is_Full_Quiz,
			LimitAssigned = CASE WHEN @Is_Full_Quiz = 1 THEN LimitAssigned ELSE 1 END
		 where AssignToStudentID = @AssignToStudentID 
	END
	ELSE
	BEGIN 
		IF @AssignmentID > 0
		BEGIN
			UPDATE dbo.tblEL_Assignments
			SET Title = @Title, 
				Instructions = @Instructions, 
				MonHocID = @MonHocID, 
				KhoiID = @KhoiID,
				AssignmentConfig = @AssignmentConfig, 
				AssignmentConfig_NoAnswer = @AssignmentConfig_NoAnswer,
				HocKi = @HocKi,
				IsBlockCopy_Paste = @IsBlockCopy_Paste,
				MaxScore = @MaxScore,
				UpdateTime = GETDATE(), UpdateUser = @sys_UserID
			WHERE AssignmentID = @AssignmentID AND CreateUser = @sys_UserID;
			SELECT AssignmentID,@AssignmentConfig_NoAnswer FROM dbo.tblEL_Assignments WHERE AssignmentID = @AssignmentID;
		END
		ELSE
		BEGIN
			INSERT INTO dbo.tblEL_Assignments (MonHocID, KhoiID, Title, Instructions, AssignmentConfig, NienKhoa, HocKi, IsBlockCopy_Paste, MaxScore, CreateUser)
			VALUES (@MonHocID, @KhoiID, @Title, @Instructions, @AssignmentConfig, @NienKhoa, @HocKi, @IsBlockCopy_Paste, @MaxScore, @sys_UserID);
			SELECT AssignmentID = SCOPE_IDENTITY(); 
		END  
	END
END
