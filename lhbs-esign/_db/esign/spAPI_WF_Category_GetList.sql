CREATE PROCEDURE [dbo].[spAPI_WF_Category_GetList]
    @sys_UserID VARCHAR(9)
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
        C.UpdateTime
    FROM dbo.tblWF_Category AS C
    WHERE C.[Enable] = 1
    ORDER BY C.SortOrder, C.CategoryID;
END
