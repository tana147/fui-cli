CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_Copy_ContentByLessonID]
	@LessonID int,
	@SYS_USERID varchar(9)
AS
BEGIN
IF @SYS_USERID ='NA0000022'
BEGIN
	SET @SYS_USERID= 'NV0000873'
END
DECLARE @LessonIDNew int
INSERT INTO dbo.tblEL_Lessons
(
    Title,
    Description,
    NienKhoa,
    HocKi,
    EstimatedDuration,
    ThumbnailURL,
    Status,
    IsDeleted,
    CreateTime,
    CreateUser,
    UpdateTime,
    UpdateUser,
    Tuan,
    TuanHocID,
    Chuong,
    KhoiID,
    MonHocID,
    IsPublic,
    IsCopy,
    CopyFromLessonID,
    CopyFromUserID,
    CopyTime
)
SELECT  [Title] + ' COPY',       -- Title - nvarchar(255)
   [Description],       -- Description - nvarchar(max)
    NienKhoa,         -- NienKhoa - int
    HocKi,         -- HocKi - tinyint
    EstimatedDuration,         -- EstimatedDuration - int
    ThumbnailURL,       -- ThumbnailURL - nvarchar(1000)
    Status,         -- Status - tinyint
    0,      -- IsDeleted - bit
    CreateTime, -- CreateTime - datetime
    CreateUser,        -- CreateUser - varchar(9)
    UpdateTime, -- UpdateTime - datetime
    UpdateUser,        -- UpdateUser - varchar(9)
    Tuan,       -- Tuan - nvarchar(50)
    TuanHocID,         -- TuanHocID - int
   Chuong,       -- Chuong - nvarchar(2000)
    KhoiID,         -- KhoiID - int
    MonHocID,         -- MonHocID - int
    0,      -- IsPublic - bit
    1,      -- IsCopy - bit
    LessonID,         -- CopyFromLessonID - int
    CreateUser,        -- CopyFromUserID - varchar(9)
    GETDATE()  -- CopyTime - datetime
    	
FROM dbo.tblEL_Lessons where LessonID = @LessonID
SELECT @LessonIDNew = LessonID FROM dbo.tblEL_Lessons WHERE LessonID = SCOPE_IDENTITY();
INSERT INTO dbo.tblEL_Elements
(
    LessonID,
    ElementType,
    ElementData,
    SortOrder,
    IsDeleted,
    CreateTime,
    CreateUser,
    UpdateTime,
    UpdateUser
)
SELECT
   @LessonIDNew,         -- LessonID - int
    ElementType,        -- ElementType - varchar(50)
    ElementData,       -- ElementData - nvarchar(max)
    SortOrder,         -- SortOrder - int
    IsDeleted,      -- IsDeleted - bit
   CreateTime, -- CreateTime - datetime
    CreateUser,        -- CreateUser - varchar(9)
    UpdateTime, -- UpdateTime - datetime
    UpdateUser         -- UpdateUser - varchar(9)
    
FROM dbo.tblEL_Elements WHERE LessonID = @LessonID
END