CREATE PROCEDURE [dbo].[spAPI_LichSuXuatSoDiem_Insert]
    @GiaoVienID NVARCHAR(50),
    @TenGiaoVien NVARCHAR(255),
    @LopID INT,
    @NhomID NVARCHAR(20),
    @TenLop NVARCHAR(100),
    @MonHocID INT,
    @TenMonHoc NVARCHAR(255),
    @HocKy INT,
    @NienKhoa INT,
    @NguoiXuatID NVARCHAR(50),
    @TenNguoiXuat NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tblLichSuXuatSoDiem
    (
        GiaoVienID,
        TenGiaoVien,
        LopID,
        NhomID,
        TenLop,
        MonHocID,
        TenMonHoc,
        HocKy,
        NienKhoa,
        ThoiGianXuat,
        NguoiXuatID,
        TenNguoiXuat
    )
    VALUES
    (
        @GiaoVienID,
        @TenGiaoVien,
        @LopID,
        @NhomID,
        @TenLop,
        @MonHocID,
        @TenMonHoc,
        @HocKy,
        @NienKhoa,
        GETDATE(),
        @NguoiXuatID,
        @TenNguoiXuat
    );

    SELECT SCOPE_IDENTITY() AS ID, GETDATE() AS ThoiGianXuat;
END