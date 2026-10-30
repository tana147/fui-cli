 -- [dbo].[spAPI_NhomAV_Get] 2025
CREATE PROC [dbo].[spAPI_NhomAV_Get] @NienKhoa INT
AS
BEGIN
    SELECT n.NhomID
         , n.MaDonVi
         , n.TenNhom
         , n.KhoiID
         , n.NienKhoa
         , n.GVCN
         , n.CapID
         , n.MonHocID
         , n.KhoiID
		 , N.ListNhomID_Child
         , mh.TenMonHoc_HienThi
		 , mh.Color
		 , n.IsNhomLMS_GiaoBai
		 , mhl.TemplateBangDiemID
		 , mhl.MonHocLopID
    FROM
           dbo.tblNhom              n
           INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = n.MonHocID
                                      AND mh.Enable   = 1
			INNER JOIN dbo.tblMonHocLop mhl ON mhl.LopNhomID = n.NhomID AND mhl.NienKhoa = @NienKhoa AND mhl.Enable = 1
    WHERE
           n.Enable  = 1
      AND  n.NienKhoa = @NienKhoa
    ORDER BY
           n.MonHocID;
END;