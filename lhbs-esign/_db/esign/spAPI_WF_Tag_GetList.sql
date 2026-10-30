CREATE PROCEDURE [dbo].[spAPI_WF_Tag_GetList]
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        T.Tag,
        T.TagName,
        T.Color,
        T.CreateUser,
        T.CreateTime,
        T.UpdateUser,
        T.UpdateTime
    FROM dbo.tblWF_Tag AS T
    WHERE T.[Enable] = 1
    ORDER BY T.TagName;
END

