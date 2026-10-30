CREATE PROC [dbo].[spAPI_LMS_Screen_Schedule_View]
    @NgayBatDau  DATE
  , @NgayKetThuc DATE
  , @Date        DATE
  , @TypeScreen  INT --0: Mobile; 1:Desktop
  , @SYS_USERID  VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM   dbo.tblLMS_View_Schedule
        WHERE  IsDeleted   = 0
          AND  Date        = @Date
          AND  NgayBatDau  = @NgayBatDau
          AND  NgayKetThuc = @NgayKetThuc
          AND  TypeScreen  = @TypeScreen
		  AND CreateUser = @SYS_USERID
    )
    BEGIN
        UPDATE dbo.tblLMS_View_Schedule
        SET    ViewCount  = ViewCount + 1
             , UpdateUser = @SYS_USERID
             , UpdateTime = GETDATE()
        WHERE  IsDeleted   = 0
          AND  Date        = @Date
          AND  NgayBatDau  = @NgayBatDau
          AND  NgayKetThuc = @NgayKetThuc
          AND  TypeScreen  = @TypeScreen
          AND  CreateUser  = @SYS_USERID
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblLMS_View_Schedule
        (
            NgayBatDau, NgayKetThuc, Date, ViewCount,
            TypeScreen, IsDeleted,
            CreateUser, CreateTime,
            UpdateUser, UpdateTime
        )
        VALUES
        (
            @NgayBatDau, @NgayKetThuc, @Date, 1,
            @TypeScreen, 0,
            @SYS_USERID, GETDATE(),
            @SYS_USERID, GETDATE()
        );
    END

END
