CREATE PROC [dbo].[spAPI_GiaiThuong_Upd]
	@Sys_UserId VARCHAR(9),
	@GiaiThuongID INT,
	@LoaiGiaiThuongID INT,
	@SoThuTu INT,
	@TenDeTai NVARCHAR(500),
	@TacGia NVARCHAR(500),
	@DonVi NVARCHAR(250),
	@Giai NVARCHAR(150),
	@ThangDatGiai INT,
	@NamDatGiai INT,
	@QDID INT
AS
BEGIN
	UPDATE dbo.GiaiThuong
	SET
	    LoaiGiaiThuongID		= @LoaiGiaiThuongID,		-- LoaiGiaiThuongID - int
	    SoThuTu					= @SoThuTu,					-- SoThuTu - int
	    TenDeTai				= @TenDeTai,				-- TenDeTai - nvarchar(500)
	    TacGia					= @TacGia,					-- TacGia - nvarchar(500)
	    DonVi					= @DonVi,					-- DonVi - nvarchar(250)
	    Giai					= @Giai,					-- Giai - nvarchar(150)
		ThangDatGiai			= @ThangDatGiai,
	    NamDatGiai				= @NamDatGiai,				-- NamDatGiai - int
		NamHoc					= 	CASE  WHEN @ThangDatGiai >= 8 THEN CONVERT(VARCHAR(4), @NamDatGiai) + '-' + CONVERT(VARCHAR(4), @NamDatGiai + 1)
										 ELSE CONVERT(VARCHAR(4), @NamDatGiai - 1) + '-' + CONVERT(VARCHAR(4), @NamDatGiai) END,
	    QDID					= CASE WHEN @QDID = 0 THEN NULL ELSE @QDID END,				-- SoQuyetDinh - nvarchar(150)
	    NhanVienCapNhat			= @Sys_UserId,				-- NhanVienCapNhat - char(9)
		ThoiGianCapNhat			= GETDATE()
	WHERE GiaiThuongID	= @GiaiThuongID
END