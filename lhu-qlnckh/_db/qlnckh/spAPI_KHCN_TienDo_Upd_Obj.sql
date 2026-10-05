CREATE PROC [dbo].[spAPI_KHCN_TienDo_Upd_Obj]
@TienDoKHCNObj NVARCHAR(MAX), 
@SYS_UserID VARCHAR(9)
AS
BEGIN

	----update vào table TienDoCapKinhPhi
	UPDATE [dbo].[KHCN_TienDoCapKinhPhi]
	SET
		[SoTT] = json.SoTT,
		[SoTien] = json.SoTien,
		[GhiChu] = json.GhiChu,
		[NgayTienDo] = json.NgayTienDo,
		[FileID] = json.FileID,
		[FileName] = json.FileName,
		[SoQD] = json.SoQD,
		[NgayQD] = json.NgayQD,
		[NhanVienCapNhat] = @SYS_UserID,
		[ThoiGianCapNhat] = GETDATE()

	FROM OPENJSON(@TienDoKHCNObj)
	WITH (
		TienDoID INT,
		SoTT TINYINT,
		SoTien NUMERIC(18,2),
		GhiChu NVARCHAR(200),
		NgayTienDo VARCHAR(10),
		FileID VARCHAR(32),
		[FileName] NVARCHAR(500),
		SoQD VARCHAR(20),
		NgayQD VARCHAR(10)
	) AS json
	WHERE [dbo].[KHCN_TienDoCapKinhPhi].TienDoID = json.TienDoID
END