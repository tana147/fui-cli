CREATE PROCEDURE dbo.spAPI_HDKH_DM_ChucDanhHocVi_GetList
    @sys_UserID VARCHAR(9)
AS
BEGIN

    SELECT
        ID,
        TenChucDanh,
        DinhMucGioChuan,
        GhiChu,
        IsActive
    FROM dbo.tblHDKH_DM_ChucDanhHocVi
    ORDER BY ID;

END
