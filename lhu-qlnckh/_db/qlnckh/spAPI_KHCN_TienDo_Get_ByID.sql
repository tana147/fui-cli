CREATE PROC [dbo].[spAPI_KHCN_TienDo_Get_ByID]
@DeTaiKHCNID INT
AS
BEGIN
	SELECT [TienDoID], 
	[DeTaiKHCNID], 
	[SoTT], 
	[SoTien], 
	[GhiChu], 
	[NgayTienDo],
	[FileID],
	[FileName],
	'/FileData/' + FileID AS FileURL,
	SoQD,
	NgayQD
	FROM [dbo].[KHCN_TienDoCapKinhPhi] WHERE DeTaiKHCNID = @DeTaiKHCNID AND Is_Xoa = 0

END