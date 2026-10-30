CREATE PROCEDURE [dbo].[spAPI_WF_Category_GetByID]
    @sys_UserID VARCHAR(9),
    @CategoryID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        C.CategoryID,
        C.Code,
        C.Name,
        C.Icon,
        C.Color,
        C.SortOrder,
        C.CreateUser,
        C.CreateTime,
        C.UpdateUser,
        C.UpdateTime,
        C.[Enable]
    FROM dbo.tblWF_Category AS C
    WHERE C.CategoryID = @CategoryID;
END
