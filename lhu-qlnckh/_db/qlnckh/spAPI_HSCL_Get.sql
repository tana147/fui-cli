CREATE PROC [dbo].[spAPI_HSCL_Get]
AS
BEGIN
	SELECT [HeSoChatLuongID]
		,  [TenHeSoChatLuong] + N': ' + CONVERT(NVARCHAR(5),[DiemHeSoChatLuong]) + N'  -  (' + [MoTaQuyDinh] + N')' AS [TenHeSoChatLuong] 
		, [DiemHeSoChatLuong]
		, [MoTaQuyDinh]
		FROM HeSoChatLuong
END
