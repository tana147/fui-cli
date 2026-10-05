	CREATE PROC [dbo].[spAPI_RPT_BBKH_GroupBy_NamHoc]
	@SYS_UserID VARCHAR(9),
	@sys_SystemRight INT
	AS
	BEGIN
		--DECLARE @MsgError NVARCHAR(500)
		--IF (@sys_SystemRight NOT IN (1,2,9))
		--BEGIN 
		--	SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		--	RAISERROR(@MsgError, 16, 1)
		--	RETURN 0;
		--END
		
		-- Tổng
		SELECT
			NamHoc AS NamHoc, SUM(CASE WHEN BB.NoiDang = N'Trong nước' THEN 1 ELSE 0 END) AS SL_TrongNuoc,
			SUM(CASE WHEN BB.NoiDang = N'Quốc tế' THEN 1 ELSE 0 END) AS SL_QuocTe,
			COUNT(*) AS SL_Tong
		FROM BaiBaoKhoaHoc BB
		GROUP BY NamHoc
		ORDER BY NamHoc

		DECLARE @YEAR AS TABLE(NamHoc VARCHAR(9))
		INSERT INTO @YEAR(NamHoc)
		SELECT DISTINCT NamHoc FROM  BaiBaoKhoaHoc BB

		DECLARE @tbl AS TABLE (NamHoc VARCHAR(9), LoaiAnPhamID INT, TenLoaiAnPham NVARCHAR(500))
		INSERT INTO @tbl(NamHoc, LoaiAnPhamID, TenLoaiAnPham)
		SELECT Y.NamHoc, L.LoaiAnPhamID, L.TenLoaiAnPham
		FROM @YEAR Y , AnPham_Loai L 
		
		-- ChiTiet
		SELECT  [BaiBaoID]
			, [SoThuTu]
			, [TenTacGia]
			, [TenDonVi]
			, [TenBaiBao]
			, [TenTapChiHoiThao]
			, [NamDang]
			, [NoiDang]
			, [IFDiemHDGSNN]
			, [TheLoai]
			, [GhiChu]
			, [FileID_List]
			, [AnPhamID]
			, [DanhMucLoaiTapChiID]
			, [TenLoaiDanhMucTapChi]
			, NamHoc
		FROM BaiBaoKhoaHoc WHERE Is_Xoa = 0
		ORDER BY NamHoc
	END