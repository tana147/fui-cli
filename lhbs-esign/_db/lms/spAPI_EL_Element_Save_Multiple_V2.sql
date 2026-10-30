-- POST lms/EL_Element_Save_Multiple_V2
-- Giữ nguyên batch contract cũ, đồng thời lưu metadata completion của từng element.
CREATE PROCEDURE [dbo].[spAPI_EL_Element_Save_Multiple_V2]
    @LessonID int,
    @Json_Elements nvarchar(max),
    @sys_UserID varchar(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISJSON(@Json_Elements) <> 1
    BEGIN
        RAISERROR(N'Danh sách element không phải JSON hợp lệ.', 16, 1);
        RETURN;
    END;

    DECLARE @Elements table (
        RowID int IDENTITY(1,1) PRIMARY KEY,
        ElementID bigint,
        ElementType varchar(50),
        ElementData nvarchar(max),
        SortOrder int,
        IsRequired bit,
        CompletionMode varchar(40),
        ExpectedDurationSeconds int,
        RequiredDurationSeconds int
    );

    INSERT INTO @Elements (
        ElementID, ElementType, ElementData, SortOrder, IsRequired,
        CompletionMode, ExpectedDurationSeconds, RequiredDurationSeconds
    )
    SELECT
        ElementID, ElementType, ElementData, SortOrder,
        ISNULL(IsRequired, 1), ISNULL(CompletionMode, 'TIME_REQUIRED'),
        ExpectedDurationSeconds, RequiredDurationSeconds
    FROM OPENJSON(@Json_Elements)
    WITH (
        ElementID bigint '$.ElementID',
        ElementType varchar(50) '$.ElementType',
        ElementData nvarchar(max) '$.ElementData',
        SortOrder int '$.SortOrder',
        IsRequired bit '$.IsRequired',
        CompletionMode varchar(40) '$.CompletionMode',
        ExpectedDurationSeconds int '$.ExpectedDurationSeconds',
        RequiredDurationSeconds int '$.RequiredDurationSeconds'
    );

    DECLARE @RowID int = 1;
    DECLARE @MaxRowID int = (SELECT COUNT(*) FROM @Elements);
    DECLARE @ElementID bigint;
    DECLARE @ElementType varchar(50);
    DECLARE @ElementData nvarchar(max);
    DECLARE @SortOrder int;
    DECLARE @IsRequired bit;
    DECLARE @CompletionMode varchar(40);
    DECLARE @ExpectedDurationSeconds int;
    DECLARE @RequiredDurationSeconds int;

    WHILE @RowID <= @MaxRowID
    BEGIN
        SELECT @ElementID = ElementID,
               @ElementType = ElementType,
               @ElementData = ElementData,
               @SortOrder = SortOrder,
               @IsRequired = IsRequired,
               @CompletionMode = CompletionMode,
               @ExpectedDurationSeconds = ExpectedDurationSeconds,
               @RequiredDurationSeconds = RequiredDurationSeconds
        FROM @Elements WHERE RowID = @RowID;

        EXEC dbo.spAPI_EL_Element_Save_V2
            @ElementID = @ElementID,
            @LessonID = @LessonID,
            @ElementType = @ElementType,
            @ElementData = @ElementData,
            @SortOrder = @SortOrder,
            @IsRequired = @IsRequired,
            @CompletionMode = @CompletionMode,
            @ExpectedDurationSeconds = @ExpectedDurationSeconds,
            @RequiredDurationSeconds = @RequiredDurationSeconds,
            @sys_UserID = @sys_UserID;

        SET @RowID += 1;
    END;

    SELECT ElementID, LessonID, ElementType, ElementData, SortOrder,
           IsRequired, CompletionMode, ExpectedDurationSeconds, RequiredDurationSeconds
    FROM dbo.tblEL_Elements
    WHERE LessonID = @LessonID AND IsDeleted = 0
    ORDER BY SortOrder;
END;
