--[dbo].[spAPI_NhomCauTrucDiem_IELTS_Get]  46, '',0
CREATE PROC [dbo].[spAPI_NhomCauTrucDiem_IELTS_Get]  
	@MonHocID INT,
 @SYS_USERID         VARCHAR(9)
  , @Sys_GroupID        INT
AS
BEGIN
    SELECT 
	DISTINCT
		  ct.MaNhomCotDiem
         , ct.TenNhomCotDiem_VI
         , ct.TenNhomCotDiem_EN
         , ct.ThuTuNhom
         , ct.Semester
	 
    FROM
           dbo.TemplateBangDiemChiTiet ct
		   INNER JOIN dbo.tblMonHocLop mhl ON mhl.TemplateBangDiemID = ct.TemplateBangDiemID
			AND  mhl.MonHocID = 76 AND mhl.Enable = 1
		   INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = 46 AND MH.Enable = 1
    WHERE
            ct.Enable              = 1
    ORDER BY
       ct.ThuTuNhom
END; 