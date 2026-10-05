
CREATE PROC [dbo].[spAPI_NCKH_Ins_Obj]
@DeTaiNCKHObj NVARCHAR(MAX),
@ThanhVienNCKHObj NVARCHAR(MAX),
@SYS_UserID VARCHAR(9)
AS
BEGIN
	DECLARE @DeTaiNCKHID INT
	-- insert vào table KHCN_DeTai
	INSERT INTO [dbo].[NCKH_DeTai]
	(
		[DotID]
		, [TenDeTaiNCKH]
		, [KhoaID]
		, [TieuBan]
		, [DiemDG1]
		, [DiemDG2]
		, [DiemDG3]
		, [DiemDG4]
		, [DiemDG5]
		, [DiemDG6]
		, [DiemPB1]
		, [DiemPB2]
		, [DiemDGTB]
		, [MoTa_SanPham]
		, [NhanVienCapNhat]
	)
	SELECT
		json.DotID,
		json.TenDeTaiNCKH,
		json.KhoaID,
		json.TieuBan,
		json.DiemDG1,
		json.DiemDG2,
		json.DiemDG3,
		json.DiemDG4,
		json.DiemDG5,
		json.DiemDG6,
		json.DiemPB1,
		json.DiemPB2,
		json.DiemDGTB,
		json.MoTa_SanPham,
		@SYS_UserID
	FROM OPENJSON(@DeTaiNCKHObj)
	WITH (
		DotID int,
		NamHoc varchar(10),
		TenDeTaiNCKH nvarchar(500),
		KhoaID varchar(10) ,
		TieuBan nvarchar(20) ,
		DiemDG1 float ,
		DiemDG2 float ,
		DiemDG3 float ,
		DiemDG4 float ,
		DiemDG5 float ,
		DiemDG6 float ,
		DiemPB1 float ,
		DiemPB2 float ,
		DiemDGTB float ,
		MoTa_SanPham nvarchar(500) 
	) AS json;
		
	IF @@ROWCOUNT > 0
		SELECT @DeTaiNCKHID = @@IDENTITY;

	--insert vào table Thành Viên 
	INSERT INTO [dbo].[NCKH_ThanhVien]
	(
		[DeTaiNCKHID],
		[STT],
		[Is_ChuNhiem],
		[Is_NhanVien],
		[Is_SinhVien],
		[MaThanhVien],
		[Ho],
		[Ten],
		[Email],
		[PhongBanID],
		[LopID],
		[SoTaiKhoan],
		[NganHang],
		[TenChuTaiKhoan],
		[NhanVienCapNhat]
	)
	SELECT
		@DeTaiNCKHID,
		json.STT,
		json.Is_ChuNhiem,
		json.Is_NhanVien,
		json.Is_SinhVien,
		json.MaThanhVien,
		json.Ho,
		json.Ten,
		json.Email,
		json.PhongBanID,
		json.LopID,
		json.SoTaiKhoan,
		json.NganHang,
		json.TenChuTaiKhoan,
		@SYS_UserID
	FROM OPENJSON(@ThanhVienNCKHObj)
	WITH (
		STT TINYINT,
		Is_ChuNhiem BIT,
		Is_NhanVien BIT,
		Is_SinhVien BIT,
		MaThanhVien VARCHAR(9),
		Ho NVARCHAR(150),
		Ten NVARCHAR(150),
		Email VARCHAR(50),
		PhongBanID NVARCHAR(250),
		LopID VARCHAR(50),
		SoTaiKhoan NVARCHAR(50),
		NganHang NVARCHAR(250),
		TenChuTaiKhoan NVARCHAR(150)
	) AS json;
END