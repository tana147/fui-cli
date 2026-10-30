-- [spAPI_HocSinhNhom_Get_ByTenNhom]  '10AV1'
CREATE PROC [dbo].[spAPI_HocSinhNhom_Get_ByTenNhom] @TenNhom VARCHAR(20)
AS
BEGIN
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
    DECLARE @NhomID NVARCHAR(15) =
            (
                SELECT TOP 1
                       NhomID
                FROM
                       dbo.tblNhom
                WHERE
                       @NienKhoa = @NienKhoa
                  AND  TenNhom    = @TenNhom
            );

    SELECT hsn.HSNhomID
         , hsn.HocSinhID
         , hsn.NhomID
         , hsn.LopID
         , hsn.SoTT       AS SoDanhBo
         , hs.Ho
         , hs.Ten
         , hs.Ho + ' ' + hs.Ten AS HoTen
         , hs.TinhTrang
         , hs.TenTinhTrang
         , hs.EnglishName
    FROM
           dbo.tblHocSinhNhom        AS hsn
           INNER JOIN dbo.tblNhom    AS n ON n.NhomID      = hsn.NhomID
                                     AND n.Enable      = 1
           INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsn.HocSinhID
                                      AND hs.TinhTrang = 0
    WHERE
           hsn.NhomID = @NhomID and hsn.Enable = 1
    ORDER BY
           hsn.SoTT;
END;