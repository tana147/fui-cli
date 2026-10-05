CREATE PROCEDURE [dbo].[spAPI_HDKH_Admin_GetDanhSachKhoa]
    @sys_UserID VARCHAR(9),
    @sys_DepartmentID VARCHAR(9)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @sys_UserID IN ('NV0000166','NV0000267') SET @sys_DepartmentID = 'KCB';
        SELECT
            MaDonVi AS KhoaID,
            TenDonVi AS TenKhoa
        FROM dbo.DonVi
        WHERE Is_Xoa             = 0
              AND CoThamGiaNCKH  = 1
              AND (
                  MaDonVi        = @sys_DepartmentID
                  OR @sys_UserID = 'GV0000611' -- account anh Tam
                  OR @sys_UserID = 'NV0000401' -- account anh Long
                  OR @sys_UserID = 'NV0000388' -- account chi Huong
                  )
        ORDER BY TenDonVi;
    END;
