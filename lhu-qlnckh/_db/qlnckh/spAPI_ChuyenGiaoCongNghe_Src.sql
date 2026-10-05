CREATE PROC [dbo].[spAPI_ChuyenGiaoCongNghe_SRC]
	@TuKhoa NVARCHAR(500)
AS
BEGIN
	SELECT TOP (30)
		cn.CGCNID,
		cn.TenDuAn,
		cn.ChuNhiemDeTai,
		cn.ThanhVienDeTai,
		cn.DonViChuNhiem,
		cn.DonViTiepNhan,
		cn.GiaTriHopDong,
		cn.NamThucHien,
		cn.SoHopDong,
		cn.FileID_List

	FROM dbo.ChuyenGiaoCongNghe cn
	WHERE cn.Is_Xoa = 0
		AND (
			@TuKhoa = '' 
			OR @TuKhoa IS NULL 
			OR ISNULL(cn.TenDuAn, '') 
					+ ISNULL(cn.ChuNhiemDeTai, '')  
					+ ISNULL(cn.ThanhVienDeTai, '')
					+ ISNULL(cn.DonViChuNhiem, '') 
					+ ISNULL(cn.DonViTiepNhan, '') COLLATE SQL_Latin1_General_CP1_CI_AI LIKE N'%' + @TuKhoa + '%'
		)
	ORDER BY cn.NamThucHien
END

