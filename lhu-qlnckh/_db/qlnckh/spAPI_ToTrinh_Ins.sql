CREATE PROC [dbo].[spAPI_ToTrinh_Ins]
@ToTrinhObj NVARCHAR(MAX)
,@AnPhamObjArr NVARCHAR(MAX)
,@SYS_UserID VARCHAR(9)
AS
BEGIN
	DECLARE @ToTrinhID INT
	-- Thực hiện chèn dữ liệu từ biến JSON vào bảng
	INSERT INTO [dbo].[ToTrinh]
		(
			[Ngay],
			[Thang],
			[Nam],
			[SoQD],
			[TieuDeQuyetDinh],
			[NamHocKhenThuong],
			[DotKhenThuong],
			[ToTrinhFileID],
			[ToTrinhFileUrl],
			[ToTrinhFileName],
			[ToTrinhLoai],
			[ToTrinhTrangThai],
			[Created_By],
			[Created_At]
		)
	SELECT
		json.Ngay,
		json.Thang,
		json.Nam,
		json.SoQD,
		json.TieuDeQuyetDinh,
		json.NamHocKhenThuong,
		json.DotKhenThuong,
		json.ToTrinhFileID,
		json.ToTrinhFileUrl,
		json.ToTrinhFileName,
		1,
		0,
		@SYS_UserID,
		GETDATE()
	FROM OPENJSON(@ToTrinhObj)
	WITH (
		Ngay INT,
		Thang INT,
		Nam INT,
		SoQD NVARCHAR(50),
		TieuDeQuyetDinh NVARCHAR(1000),
		NamHocKhenThuong VARCHAR(10),
		DotKhenThuong VARCHAR(5),
		ToTrinhFileID VARCHAR(32),
		ToTrinhFileUrl NVARCHAR(500),
		ToTrinhFileName NVARCHAR(250)
	) AS json;
	SET @ToTrinhID = @@IDENTITY
	
	/* Step 2: UPDATE THÔNG TIN TÁC GIẢ*/
    UPDATE [dbo].[AnPham]
	SET
		[ToTrinhID] = @ToTrinhID
		--[TrangThai] = 2 --Đã ra quyết định khen thưởng
		
    FROM OPENJSON(@AnPhamObjArr)
    WITH (
		AnPhamID INT
    ) AS json
	WHERE [dbo].[AnPham].[AnPhamID] = json.AnPhamID;
	
	SELECT @ToTrinhID AS ToTrinhID
END