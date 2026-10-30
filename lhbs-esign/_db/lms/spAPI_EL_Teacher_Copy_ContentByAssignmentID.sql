CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_Copy_ContentByAssignmentID]
	@AssignmentID int,
	@TuanHocID int,
	@SYS_USERID varchar(9)
AS
BEGIN
	SET @SYS_USERID= dbo.fn_GetUser_LMS(@SYS_USERID)
INSERT INTO tblEL_Assignments( 
		[Title], 
		[Instructions], 
		[Chuong],
		[Tuan],
		TuanHocID,
		MonHocID,
		KhoiID,
		MaxScore,
		[AssignmentConfig], 
		[NienKhoa], 
		[HocKi], 
		[IsDeleted], 
		IsCopy,
		CopyFromUserID,
		CopyFromAssignmentID,
		CopyTime,
		[CreateTime], 
		[CreateUser]
	)
SELECT [Title] + ' COPY', 
		[Instructions], 
		[Chuong],
		[Tuan],
		@TuanHocID,
		MonHocID,
		KhoiID,
		MaxScore,
		[AssignmentConfig], 
		[NienKhoa], 
		[HocKi], 
		[IsDeleted], 
		1,
		CreateUser,
		AssignmentID,
		GETDATE(),
		GETDATE(), 
		@SYS_USERID		
FROM tblEL_Assignments where AssignmentID = @AssignmentID
END