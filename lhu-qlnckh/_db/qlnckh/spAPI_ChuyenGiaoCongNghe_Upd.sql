
CREATE PROC [dbo].[spAPI_ChuyenGiaoCongNghe_Upd]
    @Sys_UserId VARCHAR(9),
    @CGCNID INT,
    @SoThuTu INT,
    @TenDuAn NVARCHAR(500),
    @ChuNhiemDeTai NVARCHAR(500),
    @ThanhVienDeTai NVARCHAR(500),
    @DonViChuNhiem NVARCHAR(500),
    @DonViTiepNhan NVARCHAR(500),
    @GiaTriHopDong NUMERIC(18,2),
    @NamThucHien INT,
    @SoHopDong NVARCHAR(250),
	@DS_FileID NVARCHAR(MAX),
	@NamHoc VARCHAR(10)
AS
BEGIN
    UPDATE dbo.ChuyenGiaoCongNghe
    SET
        SoThuTu = @SoThuTu,
        TenDuAn = @TenDuAn,
        ChuNhiemDeTai = @ChuNhiemDeTai,
        ThanhVienDeTai = @ThanhVienDeTai,
        DonViChuNhiem = @DonViChuNhiem,
        DonViTiepNhan = @DonViTiepNhan,
        GiaTriHopDong = @GiaTriHopDong,
        NamThucHien = @NamThucHien,
        SoHopDong = @SoHopDong,
		FileID_List = @DS_FileID,
		NamHoc = @NamHoc,
        NhanVienCapNhat = @Sys_UserId,
        ThoiGianCapNhat = GETDATE()
    WHERE CGCNID = @CGCNID
END