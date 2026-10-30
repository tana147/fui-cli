CREATE PROC [dbo].[spAPI_GiaoAn_ByGiaoVienID_Get]
@GIAOVIENID nvarchar(10)
AS
BEGIN
    SELECT 
           CTH.GiaoVienID,
           GV.HoGV,
           GV.TenGV
    FROM dbo.tblLMSChuongTrinhHoc CTH
        INNER JOIN dbo.tblGiaoVien GV
            ON GV.GiaoVienID = CTH.GiaoVienID 
    WHERE CTH.GiaoVienID = @GIAOVIENID;
END;