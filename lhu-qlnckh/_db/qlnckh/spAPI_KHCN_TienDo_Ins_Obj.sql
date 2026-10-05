CREATE PROC [dbo].[spAPI_KHCN_TienDo_Ins_Obj]
@DeTaiKHCNID INT,
@TienDoKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN

	--insert vào table TienDoCapKinhPhi
	INSERT INTO [dbo].[KHCN_TienDoCapKinhPhi]
	(
		[DeTaiKHCNID],
		[SoTT],
		[SoTien],
		[GhiChu],
		[NgayTienDo],
		[QDID],
		[FileID],
		[FileName],
		[SoQD],
		[NgayQD],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiKHCNID,
		json.SoTT,
		json.SoTien,
		json.GhiChu,
		json.NgayTienDo,
		json.QDID,
		json.FileID,
		json.FileName,
		json.SoQD,
		json.NgayQD,
		@SYS_UserID
	FROM OPENJSON(@TienDoKHCNObj)
	WITH (
		SoTT TINYINT,
		SoTien NUMERIC(18,2),
		GhiChu NVARCHAR(200),
		NgayTienDo VARCHAR(10),
		QDID INT,
		FileID VARCHAR(32),
		SoQD VARCHAR(20),
		NgayQD VARCHAR(10),
		[FileName] NVARCHAR(500)
	) AS json;
	
END