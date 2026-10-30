CREATE PROC [dbo].[spAPI_ChuKy_Get_ByUserID] @SYS_USERID VARCHAR(9)
AS
BEGIN
    SELECT convert_to_object = '',
           ck.ChuKyID,
           ck.HinhAnhChuKy,
           ck.GiaoVienID,
           gv.HoGV + ' ' + gv.TenGV AS HoTenGV
    FROM dbo.tblChuKy ck
        INNER JOIN dbo.tblGiaoVien gv
            ON gv.GiaoVienID = ck.GiaoVienID
    WHERE ck.GiaoVienID = @SYS_USERID;
END;