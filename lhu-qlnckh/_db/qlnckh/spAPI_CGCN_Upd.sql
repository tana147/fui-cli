CREATE PROCEDURE [dbo].[spAPI_CGCN_Upd]
    @CGCNID INT,
    @TenDuAn NVARCHAR(500),
    @ChuNhiemDeTai NVARCHAR(500),
    @ThanhVienDeTai NVARCHAR(500),
    @DonViChuNhiem NVARCHAR(500),
    @DonViTiepNhan NVARCHAR(500),
    @GiaTriHopDong NUMERIC(18,2),
    @NamThucHien INT,
    @SoHopDong NVARCHAR(250),
    @DS_FileID NVARCHAR(MAX),
    @NamHoc VARCHAR(10),
    @TrangThai INT,
    @LyDoReject NVARCHAR(500),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ChuyenGiaoCongNghe
    SET 
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
        NhanVienCapNhat = ISNULL(@sys_UserID, NhanVienCapNhat),
        ThoiGianCapNhat = GETDATE(),
        TrangThai = ISNULL(@TrangThai, TrangThai),
        -- Nếu chuyển sang trạng thái 2 (Chờ duyệt) thì tự động xóa lý do từ chối cũ
        LyDoReject = CASE 
            WHEN @TrangThai = 2 THEN '' 
            WHEN @LyDoReject IS NOT NULL THEN @LyDoReject
            ELSE LyDoReject 
        END,
        ThoiGianSubmit = CASE WHEN @TrangThai = 2 THEN GETDATE() ELSE ThoiGianSubmit END
    WHERE CGCNID = @CGCNID;
END;
