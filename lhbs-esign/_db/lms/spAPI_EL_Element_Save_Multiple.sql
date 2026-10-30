CREATE PROC [dbo].[spAPI_EL_Element_Save_Multiple]
	@LessonID INT,
	@Json_Elements NVARCHAR(MAX),
	@SYS_USERID varchar(9)
as
begin
	DECLARE @Table_Elements TABLE(
		RowID INT IDENTITY(1,1),
		ElementID		BIGINT ,
		LessonID		INT,
		ElementType		VARCHAR(50),
		ElementData		NVARCHAR(MAX),
		SortOrder		INT
	)

	Insert into @Table_Elements 
	(
		ElementID	,	
		LessonID	,	
		ElementType	,	
		ElementData	,	
		SortOrder			
	)
	SELECT 
		ElementID	,	
		LessonID	,	
		ElementType	,	
		ElementData	,	
		SortOrder		
	from OPENJSON (@Json_Elements)
	WITH (
		ElementID BIGINT ,
		LessonID INT,
		ElementType VARCHAR(50),
		ElementData NVARCHAR(MAX),
		SortOrder INT
	)

	DECLARE @RowIndex INT = 1
	DECLARE @MaxRow INT = (SELECT COUNT(*) FROM @Table_Elements)

	DECLARE 
		@ElementID BIGINT,
		@ElementType VARCHAR(50),
		@ElementData NVARCHAR(MAX),
		@SortOrder INT

	WHILE @RowIndex <= @MaxRow
	BEGIN
		SELECT 
			@ElementID = ElementID,
			@ElementType = ElementType,
			@ElementData = ElementData,
			@SortOrder = SortOrder
		FROM @Table_Elements
		WHERE RowID = @RowIndex

		EXEC spAPI_EL_Element_Save 
			@ElementID = @ElementID,
			@LessonID = @LessonID,
			@ElementType = @ElementType,
			@ElementData = @ElementData,
			@SortOrder = @SortOrder,
			@sys_UserID = @SYS_USERID

		SET @RowIndex = @RowIndex + 1
	END
end