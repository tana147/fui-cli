CREATE PROC [dbo].[spAPI_AnPham_Ins_ToRPT] -- '{"AnPhamID":1166}', 'GV0000611', 9
@AnPhamObjArr NVARCHAR(MAX),
@NamHoc VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
		DECLARE @MsgError NVARCHAR(500)
		IF (@sys_SystemRight NOT IN (1,2,9))
		BEGIN 
			SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
			RAISERROR(@MsgError, 16, 1)
			RETURN 0;
		END
	
	/* Step 3: INSERT VÀO BÀI BÁO*/
		DECLARE  @STT INT
		SET @STT = (SELECT MAX(SoThuTu) FROM BaiBaoKhoaHoc WHERE Is_Xoa = 0)
		INSERT INTO BaiBaoKhoaHoc([SoThuTu], [TenTacGia], [TenDonVi], [TenBaiBao], [TenTapChiHoiThao], [NamDang], [NoiDang], [IFDiemHDGSNN], [TheLoai], [GhiChu], [FileID_List], [AnPhamID], [DanhMucLoaiTapChiID], [TenLoaiDanhMucTapChi], [LoaiAnPhamID], NamHoc)
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
			, @NamHoc
		FROM OPENJSON(@AnPhamObjArr)
		WITH (
			AnPhamID INT
		) AS json 
			INNER JOIN AnPham A ON json.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_TacGia] B ON B.AnPhamID = A.AnPhamID
			INNER JOIN [dbo].[AnPham_Loai] C ON C.LoaiAnPhamID = A.LoaiAnPhamID
			WHERE  B.Is_Xoa = 0 AND A.Is_Xoa = 0 AND json.AnPhamID NOT IN (SELECT AnPhamID FROM BaiBaoKhoaHoc WHERE Is_Xoa=0 AND AnPhamID IS NOT NULL)
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