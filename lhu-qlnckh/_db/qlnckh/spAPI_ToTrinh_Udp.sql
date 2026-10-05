CREATE PROC [dbo].[spAPI_ToTrinh_Udp]
@ToTrinhObj NVARCHAR(MAX)
,@AnPhamObjArr NVARCHAR(MAX)
,@SYS_UserID VARCHAR(9)
AS
BEGIN
	DECLARE @ToTrinhID INT
	DECLARE @SoQD NVARCHAR(50)

	SELECT @ToTrinhID = ToTrinhID, @SoQD = SoQD
	FROM OPENJSON (@ToTrinhObj)
	WITH (
		ToTrinhID INT '$.ToTrinhID',
		SoQD NVARCHAR(50) '$.SoQD'
	);
	-- Cập nhật dữ liệu từ biến JSON vào bảng
	UPDATE [dbo].[ToTrinh]
	SET
		[Ngay] = json.Ngay,
		[Thang] = json.Thang,
		[Nam] = json.Nam,
		[SoQD] = json.SoQD,
		[TieuDeQuyetDinh] = json.TieuDeQuyetDinh,
		[NamHocKhenThuong] = json.NamHocKhenThuong,
		[DotKhenThuong] = json.DotKhenThuong,
		[ToTrinhFileID] = json.ToTrinhFileID,
		[ToTrinhFileUrl] = json.ToTrinhFileUrl,
		[ToTrinhFileName] = json.ToTrinhFileName,
		[ToTrinhLoai] = 1,
		[ToTrinhTrangThai] = 0,
		[Created_By] = @SYS_UserID,
		[Created_At] = GETDATE()
	FROM OPENJSON (@ToTrinhObj)
	WITH (Ngay INT
		,Thang INT
		,Nam INT
		,SoQD NVARCHAR(50)
		,TieuDeQuyetDinh NVARCHAR(1000)
		,NamHocKhenThuong VARCHAR(10)
		,DotKhenThuong VARCHAR(5)
		,ToTrinhFileID VARCHAR(32)
		,ToTrinhFileUrl NVARCHAR(500)
		,ToTrinhFileName NVARCHAR(250) 
	) AS json
	WHERE [ToTrinhID] = @ToTrinhID;

	IF @AnPhamObjArr IS NOT NULL OR @AnPhamObjArr <> '' OR @AnPhamObjArr <> '{}'
	BEGIN
		--Reset field ToTrinhID trong AnPham
		UPDATE AnPham
		SET ToTrinhID = NULL,
			--[TrangThai] = 2,
			NhanVienCapNhat = @SYS_UserID, 
			ThoiGianCapNhat = GETDATE()
			WHERE ToTrinhID = @ToTrinhID
	
		/* Step 2: UPDATE THÔNG TIN TÁC GIẢ*/
		UPDATE [dbo].[AnPham]
		SET
			[ToTrinhID] = @ToTrinhID,
			[TrangThai] = CASE WHEN ISNULL(@SoQD,'') = '' THEN 3 ELSE 4 END, --Đã ra quyết định khen thưởng
			NhanVienCapNhat = @SYS_UserID, 
			ThoiGianCapNhat = GETDATE()
		FROM OPENJSON(@AnPhamObjArr)
		WITH (
			AnPhamID INT
		) AS json
		WHERE [dbo].[AnPham].[AnPhamID] = json.AnPhamID;

		/* Step 3: INSERT VÀO BÀI BÁO*/
		DECLARE  @STT INT
		SET @STT = (SELECT MAX(SoThuTu) FROM BaiBaoKhoaHoc WHERE Is_Xoa = 0)
		INSERT INTO BaiBaoKhoaHoc([SoThuTu], [TenTacGia], [TenDonVi], [TenBaiBao], [TenTapChiHoiThao], [NamDang], [NoiDang], [IFDiemHDGSNN], [TheLoai], [GhiChu], [FileID_List], [AnPhamID], [DanhMucLoaiTapChiID], [TenLoaiDanhMucTapChi], [LoaiAnPhamID])
		SELECT DISTINCT	
			ROW_NUMBER() OVER (ORDER BY A.AnPhamID) + @STT
			, STUFF((SELECT ', ' + B.HoTacGia + ' ' + B.TenTacGia
					 FROM [dbo].[AnPham_TacGia] B
					 WHERE B.AnPhamID = A.AnPhamID AND B.Is_Xoa = 0
					 FOR XML PATH('')), 1, 2, '') AS TacGia 
			, A.DonViDaiDien
			, A.TenAnPham
			, A.TenTapChi
			, A.NamDangBai
			, A.NoiDangBai
			, A.DiemHoiDong
			, A.TenLoaiAnPham
			, A.GhiChu
			, A.FileIDAnPham
			, A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, A.LoaiAnPhamID
		FROM OPENJSON(@AnPhamObjArr)
		WITH (
			AnPhamID INT
		) AS json 
			INNER JOIN AnPham A ON json.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND json.AnPhamID NOT IN (SELECT AnPhamID FROM BaiBaoKhoaHoc WHERE Is_Xoa=0)
		GROUP BY 
			 A.DonViDaiDien
			, A.TenAnPham
			, A.TenTapChi
			, A.NamDangBai
			, A.NoiDangBai
			, A.DiemHoiDong
			, A.TenLoaiAnPham
			, A.GhiChu
			, A.FileIDAnPham
			, A.AnPhamID
			, A.DanhMucLoaiTapChiID
			, A.TenLoaiDanhMucTapChi
			, A.LoaiAnPhamID
	END
	
END


