CREATE PROCEDURE [dbo].[spAPI_WF_Category_Delete]
    @sys_UserID VARCHAR(9),
    @CategoryID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblWF_Category
    SET
        [Enable]    = 1,
        UpdateUser  = @sys_UserID,
        UpdateTime  = GETDATE()
    WHERE CategoryID = @CategoryID;
END
