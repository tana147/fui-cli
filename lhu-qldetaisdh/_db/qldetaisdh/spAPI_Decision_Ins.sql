--[dbo].[spAPI_Decision_Ins] '{
--  "Decision_TieuDe": "xxxx",
--  "Decision_Nganh": "x",
--  "Decision_NienKhoa": "",
--  "Decision_Dot": "x",
--  "Decision_MaSo": "",
--  "Decision_Type": "Type A",
--  "Decision_Description": "x",
--  "Decision_TemplateID": 1
--}','{
--  "Student_ID": [
--    "917000226",
--    "922000041"
--  ]
--}','917000226'


CREATE PROC [dbo].[spAPI_Decision_Ins] 
@Decision_Obj NVARCHAR(MAX),
@Student_Obj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	DECLARE @SoQD_Temp NVARCHAR(50) = NEWID()
	DECLARE @Decision_ID INT
	-- Thực hiện chèn dữ liệu từ biến JSON vào bảng
	INSERT INTO [dbo].[Decision]
		(
			[Decision_SoQD],
			 [Decision_TieuDe],
			 [Decision_NganhID],
			 [Decision_Nganh],
			 [Decision_NienKhoa],
			 [Decision_Dot],
			 [Decision_MaSo],
			 [Decision_Type],
			 [Decision_Description],
			 [Decision_TemplateID],
			 [Decision_Status],
			 [Created_By],
			 [Created_At]
		 )
	SELECT
		 @SoQD_Temp,
		 json.Decision_TieuDe,
		 json.Decision_NganhID,
		 json.Decision_Nganh,
		 json.Decision_NienKhoa,
		 json.Decision_Dot,
		 json.Decision_MaSo,
		 json.Decision_Type,
		 json.Decision_Description,
		 json.Decision_TemplateID,
		 1,
		 @SYS_UserID,
		 GETDATE()
		FROM OPENJSON(@Decision_Obj)
        WITH (
            Decision_TieuDe NVARCHAR(500),
            Decision_NganhID INT,
			Decision_Nganh NVARCHAR(200),
            Decision_NienKhoa NVARCHAR(20),
            Decision_Dot NVARCHAR(10),
            Decision_MaSo NVARCHAR(50),
            Decision_Type NVARCHAR(20),
            Decision_Description NVARCHAR(MAX),
            Decision_TemplateID TINYINT
        ) AS json;

	SET @Decision_ID = @@IDENTITY

	IF @@ROWCOUNT >0
	BEGIN
		--DECLARE @SoQD_Te = (SELECT Decision_SoQD FROM Decision WHERE Decision_ID = @@IDENTITY)
		DECLARE @Students_tmp AS TABLE (Student_ID VARCHAR(9))
		INSERT INTO @Students_tmp (Student_ID)
		SELECT value AS Student_ID
		FROM OPENJSON(@Student_Obj, '$.Student_ID')
		
		UPDATE Flow_Detail
		SET Flow_Detail.Text_Content = @SoQD_Temp
		FROM @Students_tmp S
				INNER JOIN Flow F	ON F.Student_ID = S.Student_ID
				INNER JOIN Flow_Detail FD ON FD.Flow_ID = F.Flow_ID
				INNER JOIN Task_Detail TD ON TD.Task_Detail_ID = FD.Task_Detail_ID
		WHERE TD.FieldName = 'ThesisConfirmNo'

	END

	SELECT @Decision_ID AS Decision_ID

END