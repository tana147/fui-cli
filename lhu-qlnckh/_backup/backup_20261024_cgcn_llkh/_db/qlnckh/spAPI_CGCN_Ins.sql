CREATE PROCEDURE [dbo].[spAPI_CGCN_Ins]
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
    @TrangThai INT,
    @NhanVienSubmit CHAR(9),
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserAction CHAR(9) = ISNULL(@NhanVienSubmit, @sys_UserID);
    DECLARE @Status INT = ISNULL(@TrangThai, 1); -- Mặc định là 1 (Dự thảo)

    DECLARE @STT INT;
    SELECT @STT = ISNULL(MAX(SoThuTu), 0) + 1 FROM dbo.ChuyenGiaoCongNghe WHERE Is_Xoa = 0;

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
        Is_Xoa,
        NhanVienSubmit,
        TrangThai,
        ThoiGianSubmit
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
        @UserAction,
        GETDATE(),
        0,
        @UserAction,
        @Status,
        CASE WHEN @Status = 2 THEN GETDATE() ELSE NULL END
    );

    SELECT SCOPE_IDENTITY() AS NewCGCNID;
END;
