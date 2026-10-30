CREATE PROCEDURE [dbo].[spAPI_WF_Category_Insert]
    @sys_UserID VARCHAR(9),
    @Code       NVARCHAR(50),
    @Name       NVARCHAR(255),
    @Icon       NVARCHAR(100)   = NULL,
    @Color      NVARCHAR(50)    = NULL,
    @SortOrder  INT             = 0,
    @NewID      INT             OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblWF_Category
        (Code, Name, Icon, Color, SortOrder, CreateUser, CreateTime, UpdateUser, UpdateTime, [Enable])
    VALUES
        (@Code, @Name, @Icon, @Color, @SortOrder,
         @sys_UserID, GETDATE(),
         @sys_UserID, GETDATE(),
         0);

    SET @NewID = SCOPE_IDENTITY();
END
