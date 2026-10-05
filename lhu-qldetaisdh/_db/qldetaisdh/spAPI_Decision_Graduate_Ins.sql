
CREATE PROC [dbo].[spAPI_Decision_Graduate_Ins]
@JsonStudentData NVARCHAR(MAX),
@Decision_SoQD NVARCHAR(50),
@Decision_NgayQD VARCHAR(2),
@Decision_ThangQD VARCHAR(2),
@Decision_NamQD VARCHAR(4),
@Decision_TieuDe NVARCHAR(500),
@Decision_Dot NVARCHAR(10),
--@Decision_NganhID INT,
@Decision_NienKhoa NVARCHAR(20),

@SYS_UserID VARCHAR(9),
@Sys_GroupID INT,
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
	
	DECLARE @TempTable AS TABLE (StudentID VARCHAR(20) NOT NULL)
	--DECLARE @TenNganh NVARCHAR(250)
	--DECLARE @MaNganh VARCHAR(50)
	DECLARE @InsertedDecision TABLE (Decision_ID INT)

	INSERT INTO @TempTable (StudentID)
	SELECT *
	FROM OPENJSON(@JsonStudentData)
	WITH (StudentID VARCHAR(20) '$.StudentID')

	--SELECT 
	--	@TenNganh = TenNganh,
	--	@MaNganh = MaNganh
	--FROM Nganh
	--WHERE NganhID = @Decision_NganhID

	INSERT INTO Decision
	(
		Decision_SoQD,
		Decision_NgayQD,
		Decision_ThangQD,
		Decision_NamQD,
		Decision_TieuDe,
		--Decision_NganhID,
		--Decision_Nganh,
		Decision_NienKhoa,
		Decision_Dot,
		--Decision_MaSo,
		Decision_Type,
		Created_By,
		Created_At
	)
	OUTPUT INSERTED.Decision_ID INTO @InsertedDecision
	VALUES
	(
		@Decision_SoQD,
		@Decision_NgayQD,
		@Decision_ThangQD,
		@Decision_NamQD,
		@Decision_TieuDe,
		--@Decision_NganhID,
		--@TenNganh,
		@Decision_NienKhoa,
		@Decision_Dot,
		--@MaNganh,
		N'Xét tốt nghiệp',
		@SYS_UserID,
		GETDATE()
	)

	INSERT INTO Decision_Graduate
	(
		Decision_ID,
		StudentID,
		Use_YN,
		Created_By,
		Created_At
	)
	SELECT 
		d.Decision_ID,
		StudentID,
		1,
		@SYS_UserID,
		GETDATE()
	FROM @TempTable
	CROSS JOIN @InsertedDecision d
END