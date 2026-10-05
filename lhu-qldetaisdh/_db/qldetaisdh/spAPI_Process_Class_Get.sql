CREATE PROC [dbo].[spAPI_Process_Class_Get]
AS
BEGIN
	SELECT * FROM [dbo].[Process_Class]
    where ProcessClassStatus = 0
END
