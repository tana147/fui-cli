CREATE PROC [dbo].[spAPI_HocSinhBangDiem_Get_ByMonHocID_MaNhom_1] --'N241001', 76, 78, 'Theme_1', 'NA0000022',9
    @LopID VARCHAR(10),
    @MonHocID INT,
    @TemplateBangDiemID INT,
    @MaNhomCotDiem NVARCHAR(100),
    @SYS_USERID VARCHAR(9),
    @Sys_GroupID INT
AS
BEGIN
	
	DECLARE @LopNhomID varchar(10)
	SET @LopNhomID = @LopID
    -- Truy vấn tối ưu sử dụng LEFT JOIN
    -- Truy vấn khi LopID là số
	SELECT 
		HS.[HocSinhID],
		HSL.SoDanhBo,
		HS.[Ho],
		HS.[Ten],
		HS.[NgaySinh],
		HS.[Nu],
		BD.CotDiemID AS CotDiemID,
		BD.MaCotDiem,
		BD.LoaiCotDiem,
		BD.GiaTriCotDiem AS GiaTriCotDiem,
		BD.KieuDanhGiaID,
		BD.TenCotDiem_VI,
		BD.TenCotDiem_EN,
		BD.ThuTuCotDiem,
		BD.MaNhomCotDiem,
		BD.TenNhomCotDiem_VI,
		BD.TenNhomCotDiem_EN,
		KQ.KetQuaDanhGia_VI,
		KQ.KetQuaDanhGia_EN,
		BD.HexBackground,
		BD.Formula,
		BD.DiemMin,
		BD.DiemMax,
		BD.QuyenNhapDiem,
		ISNULL(KQ.TinhTrang, 0) AS TinhTrang
	FROM dbo.tblHocSinh HS
	INNER JOIN dbo.tblHocSinhLop HSL
		ON HS.HocSinhID = HSL.HocSinhID
		AND HSL.LopID = @LopID 
	INNER JOIN dbo.tblMonHocLop MHL
		ON MHL.LopNhomID = HSL.LopID
		   AND MHL.TemplateBangDiemID = @TemplateBangDiemID
	INNER JOIN dbo.TemplateBangDiemChiTiet BD
		ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
		   AND BD.MaNhomCotDiem = @MaNhomCotDiem
	LEFT JOIN dbo.tblKetQuaHocTap KQ
		ON KQ.HocSinhID = HS.HocSinhID
		   AND KQ.CotDiemID = BD.CotDiemID
		   AND KQ.MonHocLopID = MHL.MonHocLopID
	WHERE HS.TinhTrang = 0
		  AND HSL.Enable = 1
	
	UNION ALL

	-- Truy vấn khi LopID là chuỗi
	SELECT 
		HS.[HocSinhID],
		HSN.SoTT,
		HS.[Ho],
		HS.[Ten],
		HS.[NgaySinh],
		HS.[Nu],
		BD.CotDiemID AS CotDiemID,
		BD.MaCotDiem,
		BD.LoaiCotDiem,
		BD.GiaTriCotDiem AS GiaTriCotDiem,
		BD.KieuDanhGiaID,
		BD.TenCotDiem_VI,
		BD.TenCotDiem_EN,
		BD.ThuTuCotDiem,
		BD.MaNhomCotDiem,
		BD.TenNhomCotDiem_VI,
		BD.TenNhomCotDiem_EN,
		KQ.KetQuaDanhGia_VI,
		KQ.KetQuaDanhGia_EN,
		BD.HexBackground,
		BD.Formula,
		BD.DiemMin,
		BD.DiemMax,
		BD.QuyenNhapDiem,
		ISNULL(KQ.TinhTrang, 0) AS TinhTrang
	FROM dbo.tblHocSinh HS
	INNER JOIN dbo.tblHocSinhNhom HSN
		ON HS.HocSinhID = HSN.HocSinhID
		AND HSN.NhomID = @LopNhomID
	INNER JOIN dbo.tblMonHocLop MHL
		ON MHL.LopNhomID = HSN.NhomID
		   AND MHL.TemplateBangDiemID = @TemplateBangDiemID
	INNER JOIN dbo.TemplateBangDiemChiTiet BD
		ON BD.TemplateBangDiemID = MHL.TemplateBangDiemID
		   AND BD.MaNhomCotDiem = @MaNhomCotDiem
	LEFT JOIN dbo.tblKetQuaHocTap KQ
		ON KQ.HocSinhID = HS.HocSinhID
		   AND KQ.CotDiemID = BD.CotDiemID
		   AND KQ.MonHocLopID = MHL.MonHocLopID
	WHERE HS.TinhTrang = 0
	ORDER BY HSL.SoDanhBo, BD.ThuTuCotDiem;

END;