CREATE PROCEDURE spAPI_HDKH_DM_GetTheLoaiSach
AS
BEGIN
    SELECT ID AS value, TenTheLoai AS title FROM dbo.tblHDKH_DM_TheLoaiSach WHERE IsActive = 1;
END
