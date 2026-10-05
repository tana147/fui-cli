
CREATE PROC spAPI_NCKH_Udp_Obj
@DeTaiNCKHID INT,
@DeTaiNCKHObj NVARCHAR(MAX),
@ThanhVienNCKHObj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN
	-- update vào table NCKH_DeTai
	UPDATE [dbo].[NCKH_DeTai]
	SET
		[DotID] = json.DotID,
		[TenDeTaiNCKH] = json.TenDeTaiNCKH,
		[KhoaID] = json.KhoaID,
		[TieuBan] = json.TieuBan,
		[DiemDG1] = json.DiemDG1,
		[DiemDG2] = json.DiemDG2,
		[DiemDG3] = json.DiemDG3,
		[DiemDG4] = json.DiemDG4,
		[DiemDG5] = json.DiemDG5,
		[DiemDG6] = json.DiemDG6,
		[DiemPB1] = json.DiemPB1,
		[DiemPB2] = json.DiemPB2,
		[DiemDGTB] = json.DiemDGTB,
		[MoTa_SanPham] = json.MoTa_SanPham,
		[NhanVienCapNhat] = @SYS_UserID
	FROM OPENJSON(@DeTaiNCKHObj)
	WITH (
		DotID INT,
		TenDeTaiNCKH NVARCHAR(500),
		KhoaID VARCHAR(10),
		TieuBan NVARCHAR(20),
		DiemDG1 FLOAT,
		DiemDG2 FLOAT,
		DiemDG3 FLOAT,
		DiemDG4 FLOAT,
		DiemDG5 FLOAT,
		DiemDG6 FLOAT,
		DiemPB1 FLOAT,
		DiemPB2 FLOAT,
		DiemDGTB FLOAT,
		MoTa_SanPham NVARCHAR(500),
		NhanVienCapNhat CHAR(9)
	) AS json
	WHERE [dbo].[NCKH_DeTai].DeTaiNCKHID = @DeTaiNCKHID

END
