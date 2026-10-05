CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_NhanVien_Insert] @sys_GroupID INT,
@sys_UserID VARCHAR(9),
@MaNV VARCHAR(9),
@HoTen NVARCHAR(250),
@ChucVu NVARCHAR(50),
@MaDonVi VARCHAR(9),
@HocViID INT,
@Is_ThamGiaNCKH BIT AS BEGIN
SET
NOCOUNT ON;

IF EXISTS (
    SELECT
        1
    FROM
        NhanVien
    WHERE
        MaNV = @MaNV
        AND IsActive = 1
) BEGIN RAISERROR (N'Nhân viên đã tồn tại', 16, 1) RETURN 0 END
INSERT INTO
    NhanVien (
        MaNV,
        HoTen,
        ChucVu,
        MaDonVi,
        HocViID,
        Is_ThamGiaNCKH,
        IsActive,
        CreateUser,
        CreateTime
    )
VALUES
    (
        @MaNV,
        @HoTen,
        @ChucVu,
        @MaDonVi,
        @HocViID,
        @Is_ThamGiaNCKH,
        1,
        @sys_UserID,
        GETDATE()
    ) END;

