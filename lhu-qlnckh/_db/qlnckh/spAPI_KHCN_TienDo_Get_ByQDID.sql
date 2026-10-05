CREATE PROC [dbo].[spAPI_KHCN_TienDo_Get_ByQDID]-- 146
@QDID INT
AS
BEGIN
	SELECT [TienDoID], 
	TD.[DeTaiKHCNID], 
	[NhomKHCNID],
	[MaSoDeTai],
	[TenDeTaiKHCN_Vi],
	[TenDeTaiKHCN_En],
	[SoTT], 
	TD.[SoTien], 
	TD.[GhiChu], 
	[NgayTienDo],
	[FileID],
	[FileName],
	'/FileData/' + FileID AS FileURL,
	SoQD,
	NgayQD
	FROM [dbo].[KHCN_TienDoCapKinhPhi] TD INNER JOIN KHCN_DeTai DT ON TD.DeTaiKHCNID = DT.DeTaiKHCNID

	WHERE QDID = @QDID AND TD.Is_Xoa = 0

END