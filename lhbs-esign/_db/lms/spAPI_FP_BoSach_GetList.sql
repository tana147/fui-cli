CREATE PROC spAPI_FP_BoSach_GetList
AS
BEGIN
    SELECT BoSachID
         , TenBoSach
         , MoTa
         , ThumbnailURL
         , TrangThai
    FROM
           dbo.tblBoSach_FP
    WHERE
           Is_Xoa = 0;
END;