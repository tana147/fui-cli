CREATE   PROCEDURE [dbo].[spAPI_HDKH_Admin_NhanVien_Delete] @sys_UserID VARCHAR(9),
@MaNV VARCHAR(9) AS BEGIN
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
    IsActive = 0,
    UpdateTime = GETDATE(),
    UpdateUser = @sys_UserID
WHERE
    MaNV = @MaNV END;

