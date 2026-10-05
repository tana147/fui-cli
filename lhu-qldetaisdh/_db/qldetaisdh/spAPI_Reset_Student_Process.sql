CREATE PROC [dbo].[spAPI_Reset_Student_Process]
@Student_ID VARCHAR(20),
@LyDo NVARCHAR(200),

@SYS_UserID VARCHAR(9),
@Sys_GroupID INT,
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)

	DECLARE @IsTienSi BIT = 0
	IF EXISTS (
		SELECT 1 FROM StudentInfo 
		WHERE StudentID = @Student_ID 
		  AND (HeDaoTao = 'Phd' OR SUBSTRING(LopID, 3, 1) = 'N' OR NganhID IN ('43', '44'))
	)
	BEGIN
		SET @IsTienSi = 1
	END

	IF @IsTienSi = 1
	BEGIN
		-- Tiến sĩ: FunctionRight = 2 (hoặc SystemRight = 9 admin)
		IF (@sys_SystemRight <> 9 AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
		BEGIN
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	ELSE
	BEGIN
		-- Thạc sĩ: giữ như cũ
		IF (@sys_SystemRight NOT IN (2,3,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	END
	
	DECLARE @ProcessStudent_ID INT

	SELECT @ProcessStudent_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @Student_ID

	IF (@ProcessStudent_ID IS NULL)
	BEGIN
		-----Không tìm thấy Process student ID
		SET @MsgError = N'Không tìm thấy học viên'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0
	END

	----------Insert Flow_His------------
	INSERT INTO Flow_His
	(
	Student_ID
	,Flow_ID
	,Process_Student_ID
	,Process_ID
	,Task_Parent
	,Task_ID
	,Seq
	,Task_Require
	,Flow_Status
	,LyDo
	,use_yn
	,Created_By
	,Created_At
	)
	SELECT 
		@Student_ID
		,Flow_ID
		,Process_Student_ID
		,Process_ID
		,Task_Parent
		,Task_ID
		,Seq
		,Task_Require
		,Flow_Status
		,@LyDo
		,1
		,@SYS_UserID
		,GETDATE()
	FROM Flow
	WHERE Process_Student_ID = @ProcessStudent_ID 
	  AND (
			Flow_Status IN ('P', 'C')
			OR Flow_ID IN (
				SELECT DISTINCT Flow_ID 
				FROM Flow_Detail 
				WHERE (File_ID IS NOT NULL OR Text_Content IS NOT NULL OR File_Name IS NOT NULL OR Flow_Detail_Status IN ('P', 'C'))
			)
	  )

	----------Insert Flow_Detail_His------------
	INSERT INTO Flow_Detail_His
	(
	Student_ID
	,Flow_Detail_ID
	,Flow_ID
	,Task_ID
	,Task_Detail_ID
	,File_URL
	,Text_Content
	,File_Name
	,File_ID
	,File_Type
	,Flow_Detail_Status
	,LyDo
	,use_yn
	,Created_By
	,Created_At
	)
	SELECT 
	@Student_ID
	,FD.Flow_Detail_ID
	,FD.Flow_ID
	,FD.Task_ID
	,FD.Task_Detail_ID
	,FD.File_URL
	,FD.Text_Content
	,FD.File_Name
	,FD.File_ID
	,FD.File_Type
	,FD.Flow_Detail_Status
	,@LyDo
	,1
	,@SYS_UserID
	,GETDATE()
	FROM Flow_Detail FD
	INNER JOIN Flow F ON FD.Flow_ID = F.Flow_ID
	WHERE F.Process_Student_ID = @ProcessStudent_ID 
	  AND (
			F.Flow_Status IN ('P', 'C')
			OR F.Flow_ID IN (
				SELECT DISTINCT Flow_ID 
				FROM Flow_Detail 
				WHERE (File_ID IS NOT NULL OR Text_Content IS NOT NULL OR File_Name IS NOT NULL OR Flow_Detail_Status IN ('P', 'C'))
			)
	  )
END
