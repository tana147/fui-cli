

CREATE PROC [dbo].[spAPI_Decision_Udp] 
@Decision_Obj NVARCHAR(MAX),
@Student_Obj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @SoQD_Temp NVARCHAR(50) = NEWID()
	DECLARE @SoQD_HIENTAI NVARCHAR(50);

	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END
	
    DECLARE
		@Decision_ID INT
        ,@Decision_TieuDe NVARCHAR(500)
		,@Decision_NganhID INT
		,@Decision_Nganh NVARCHAR(200)
		,@Decision_NienKhoa NVARCHAR(20)
		,@Decision_Dot NVARCHAR(10)
		,@Decision_MaSo NVARCHAR(50)
		,@Decision_Type NVARCHAR(20)
		,@Decision_Description NVARCHAR(MAX)
		,@Decision_TemplateID TINYINT
	-- Thực hiện chèn dữ liệu từ biến JSON vào bảng
	SELECT
		 @Decision_ID = json.Decision_ID
        ,@Decision_TieuDe = json.Decision_TieuDe
		,@Decision_NganhID  = json.Decision_NganhID
		,@Decision_Nganh = json.Decision_Nganh
		,@Decision_NienKhoa = json.Decision_NienKhoa
		,@Decision_Dot = json.Decision_Dot
		,@Decision_MaSo = json.Decision_MaSo
		,@Decision_Type = json.Decision_Type
		,@Decision_Description = json.Decision_Description
		,@Decision_TemplateID = json.Decision_TemplateID
		FROM OPENJSON(@Decision_Obj)
        WITH (
			Decision_ID INT,
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

	SET @SoQD_HIENTAI = (SELECT D.Decision_SoQD FROM Decision D WHERE D.Decision_ID = @Decision_ID)

	-- 1. Update Bảng Decision
	UPDATE Decision
	SET 
			Decision_TieuDe = @Decision_TieuDe,
            Decision_NganhID = @Decision_NganhID,
			Decision_Nganh = @Decision_Nganh,
            Decision_NienKhoa = @Decision_NienKhoa,
            Decision_Dot = @Decision_Dot,
            Decision_MaSo = @Decision_MaSo,
            Decision_Type = @Decision_Type,
            Decision_Description = @Decision_Description,
            Decision_TemplateID = @Decision_TemplateID
	WHERE Decision_ID = @Decision_ID

	-- 2. Update Reset những học viên đi kèm trong quyết định cũ
	UPDATE Flow_Detail
		SET Flow_Detail.Text_Content = NULL
		FROM	Flow F	
				INNER JOIN Flow_Detail FD ON FD.Flow_ID = F.Flow_ID
				INNER JOIN Task_Detail TD ON TD.Task_Detail_ID = FD.Task_Detail_ID
		WHERE TD.FieldName = 'ThesisConfirmNo' AND FD.Text_Content = @SoQD_HIENTAI
	
	-- 3. Cập nhật học viên mới (cập nhật lại)
	IF @@ROWCOUNT >0
	BEGIN
		DECLARE @Students_tmp AS TABLE (Student_ID VARCHAR(9))
		INSERT INTO @Students_tmp (Student_ID)
		SELECT value AS Student_ID
		FROM OPENJSON(@Student_Obj, '$.Student_ID')
		
		UPDATE Flow_Detail
		SET Flow_Detail.Text_Content = @SoQD_HIENTAI
		FROM @Students_tmp S
				INNER JOIN Flow F	ON F.Student_ID = S.Student_ID
				INNER JOIN Flow_Detail FD ON FD.Flow_ID = F.Flow_ID
				INNER JOIN Task_Detail TD ON TD.Task_Detail_ID = FD.Task_Detail_ID
		WHERE TD.FieldName = 'ThesisConfirmNo'

	END

	SELECT @Decision_ID AS Decision_ID

END