CREATE PROCEDURE spAPI_EL_TeacherPermissions_Ins
		@AssignToClassID	INT,
		@IsGrade			BIT,
		@IsEdit				BIT, 
		@CreateTime			DATETIME, 
		@CreateUser			VARCHAR(9), 
		@GiaoVienID			VARCHAR(9),
		@MonHocID			INT, 
		@NienKhoa			INT
AS
BEGIN
	INSERT INTO tblEL_Resoucre_TeacherPermissions(AssignToClassID, IsGrade,	IsEdit,CreateTime, CreateUser,GiaoVienID, MonHocID,NienKhoa)
	VALUES(
		@AssignToClassID,
		@IsGrade		,
		@IsEdit			,
		@CreateTime		,
		@CreateUser		,
		@GiaoVienID		,
		@MonHocID		,
		@NienKhoa		
	)
END