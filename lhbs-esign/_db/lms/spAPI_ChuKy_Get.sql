CREATE PROC [dbo].[spAPI_ChuKy_Get]
AS
BEGIN
    SELECT CK.ChuKyID,
           CK.GiaoVienID,
           GV.HoGV + ' ' + GV.TenGV AS HoTenGV,
           CK.HinhAnhChuKy
    FROM dbo.tblChuKy CK
        INNER JOIN dbo.tblGiaoVien GV
            ON GV.GiaoVienID = CK.GiaoVienID 
    WHERE CK.Enable = 1;
END;