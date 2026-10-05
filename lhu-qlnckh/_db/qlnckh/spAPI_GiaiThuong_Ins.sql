CREATE PROC [dbo].[spAPI_GiaiThuong_Ins]
	@Sys_UserId VARCHAR(9),
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
	INSERT INTO dbo.GiaiThuong
	(
	    LoaiGiaiThuongID,
	    SoThuTu,
	    TenDeTai,
	    TacGia,
	    DonVi,
	    Giai,
		ThangDatGiai,
	    NamDatGiai,
		NamHoc,
	    QDID,
		FileID_List,
	    NhanVienCapNhat
	)
	VALUES
	(   
		@LoaiGiaiThuongID,       -- LoaiGiaiThuongID - int
	    @SoThuTu, -- SoThuTu - int
	    @TenDeTai,     -- TenDeTai - nvarchar(500)
	    @TacGia,     -- TacGia - nvarchar(500)
	    @DonVi,     -- DonVi - nvarchar(250)
	    @Giai,     -- Giai - nvarchar(150)
		@ThangDatGiai,
	    @NamDatGiai,       -- NamDatGiai - int
		CASE  WHEN @ThangDatGiai >= 8 THEN CONVERT(VARCHAR(4), @NamDatGiai) + '-' + CONVERT(VARCHAR(4), @NamDatGiai + 1)
        ELSE CONVERT(VARCHAR(4), @NamDatGiai - 1) + '-' + CONVERT(VARCHAR(4), @NamDatGiai) END,
     
	    @QDID,    -- SoQuyetDinh - nvarchar(150)
		'',
	    @Sys_UserId      -- NhanVienCapNhat - char(9)
	)
END