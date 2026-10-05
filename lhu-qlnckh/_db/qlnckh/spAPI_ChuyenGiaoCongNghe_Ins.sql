CREATE PROCEDURE [dbo].[spAPI_ChuyenGiaoCongNghe_Ins]
    @SoThuTu INT,
    @TenDuAn NVARCHAR(500),
    @ChuNhiemDeTai NVARCHAR(500),
    @ThanhVienDeTai NVARCHAR(500),
    @DonViChuNhiem NVARCHAR(500),
    @DonViTiepNhan NVARCHAR(500),
    @GiaTriHopDong NUMERIC(18,2),
    @NamThucHien INT,
    @SoHopDong NVARCHAR(250),
	@DS_FileID NVARCHAR(2000),
	@NamHoc VARCHAR(10),
    @NhanVienCapNhat CHAR(9)
AS
BEGIN
	
	DECLARE @STT INT
	SELECT @STT = MAX(SoThuTu) +1 FROM ChuyenGiaoCongNghe WHERE Is_Xoa = 0
    INSERT INTO dbo.ChuyenGiaoCongNghe
    (
        SoThuTu,
        TenDuAn,
        ChuNhiemDeTai,
        ThanhVienDeTai,
        DonViChuNhiem,
        DonViTiepNhan,
        GiaTriHopDong,
        NamThucHien,
        SoHopDong,
		FileID_List,
		NamHoc,
        NhanVienCapNhat,
        ThoiGianCapNhat,
        Is_Xoa
    )
    VALUES
    (
        @STT,
        @TenDuAn,
        @ChuNhiemDeTai,
        @ThanhVienDeTai,
        @DonViChuNhiem,
        @DonViTiepNhan,
        @GiaTriHopDong,
        @NamThucHien,
        @SoHopDong,
		@DS_FileID,
		@NamHoc,
        @NhanVienCapNhat,
        GETDATE(), -- Thời gian cập nhật là thời điểm hiện tại
        0 -- Is_Xoa mặc định là 0 (chưa xóa)
    )
END
