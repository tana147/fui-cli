CREATE PROCEDURE [dbo].[spAPI_WF_Category_Update]
    @sys_UserID VARCHAR(9),
    @CategoryID INT,
    @Code       NVARCHAR(50),
    @Name       NVARCHAR(255),
    @Icon       NVARCHAR(100)   = NULL,
    @Color      NVARCHAR(50)    = NULL,
    @SortOrder  INT             = 0
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_Category
    SET
        Code        = @Code,
        Name        = @Name,
        Icon        = @Icon,
        Color       = @Color,
        SortOrder   = @SortOrder,
        UpdateUser  = @sys_UserID,
        UpdateTime  = GETDATE()
    WHERE CategoryID = @CategoryID
      AND [Enable]   = 0;
END
