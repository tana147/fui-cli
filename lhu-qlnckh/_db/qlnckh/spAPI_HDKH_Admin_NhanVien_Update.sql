CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_NhanVien_Update] @sys_GroupID INT,
@sys_UserID VARCHAR(9),
@MaNV VARCHAR(9),
@HoTen NVARCHAR(250),
@ChucVu NVARCHAR(50),
@MaDonVi varchar(9),
@HocViID INT,
@Is_ThamGiaNCKH BIT AS BEGIN
SET
NOCOUNT ON;

IF NOT EXISTS (
    SELECT
        1
    FROM
        NhanVien
    WHERE
        MaNV = @MaNV
        AND IsActive = 1
) BEGIN RAISERROR (N'Nhân viên không có trong hệ thống', 16, 1) RETURN 0 END
UPDATE NhanVien
SET
    HoTen = @HoTen,
    ChucVu = @ChucVu,
    MaDonVi = @MaDonVi,
    HocViID = @HocViID,
    Is_ThamGiaNCKH = @Is_ThamGiaNCKH,
    UpdateTime = GETDATE(),
    UpdateUser = @sys_UserID
WHERE
    MaNV = @MaNV END;

