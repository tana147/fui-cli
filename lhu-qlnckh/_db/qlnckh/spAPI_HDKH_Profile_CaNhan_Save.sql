CREATE PROCEDURE [dbo].[spAPI_HDKH_Profile_CaNhan_Save]
    @NgaySinh DATE = NULL,
    @GioiTinh NVARCHAR(10) = NULL,
    @HocVi NVARCHAR(100) = NULL,
    @ChucVu NVARCHAR(100) = NULL,
    @DienThoai VARCHAR(20) = NULL,
    @HuongNghienCuuChinh NVARCHAR(MAX) = NULL,

    @HoTen NVARCHAR(150),
    @Email VARCHAR(100),
    @DonVi NVARCHAR(255),
	@NhanVienID VARCHAR(9),
    
    -- Tham số hệ thống
    @sys_UserID VARCHAR(9),
    @sys_RawData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    MERGE dbo.tblHDKH_Profile_CaNhan AS T
    USING (SELECT @NhanVienID AS NhanVienID) AS S
    ON (T.NhanVienID = S.NhanVienID)
    WHEN MATCHED THEN
        UPDATE SET
            NgaySinh = @NgaySinh,
            GioiTinh = @GioiTinh,
            HocVi = @HocVi,
            ChucVu = @ChucVu,
            DienThoai = @DienThoai,
            HuongNghienCuuChinh = @HuongNghienCuuChinh,
            UpdateTime = GETDATE(),
            UpdateUser = @sys_UserID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (NhanVienID, HoTen, Email, DonVi, NgaySinh, GioiTinh, HocVi, ChucVu, DienThoai, HuongNghienCuuChinh, CreateUser)
        VALUES (@NhanVienID, @HoTen, @Email, @DonVi, @NgaySinh, @GioiTinh, @HocVi, @ChucVu, @DienThoai, @HuongNghienCuuChinh, @sys_UserID);

    SELECT Message = N'Cập nhật thông tin cá nhân thành công.';
END
