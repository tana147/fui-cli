CREATE PROCEDURE [dbo].[spAPI_GiaoVienLopAll_Get]
AS
BEGIN
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
   
    SELECT tgvl.GVLopID
         , tgvl.VaiTro
         , CASE WHEN tgvl.VaiTro = 3 THEN N'Giáo viên giảng dạy' END AS TenVaiTro
         , tgv.GiaoVienID
         , tgv.HoGV + ' ' + tgv.TenGV                                AS HoTen
         , tgvl.LopID  
         ,  COALESCE(tl.TenLop, tn.TenNhom) as TenLop
         , tgv.TenGV 
         , tmh.MonHocID
		 , tmh.MonHocName
         , tmh.TenMonDuLieuNganh
         , tmh.Color
         , tk.TenKhoiHoc
    FROM
        
           dbo.tblGiaoVienLop tgvl INNER JOIN    dbo.tblGiaoVien              tgv     
           ON tgv.GiaoVienID = tgvl.GiaoVienID AND tgvl.Enable = 1 AND tgvl.NienKhoa = @NienKhoa
          LEFT JOIN dbo.tblLop         tl ON tl.LopID         = tgvl.LopID AND tl.Enable = 1 AND tl.NienKhoa = tgvl.NienKhoa
          LEFT JOIN dbo.tblNhom tn  ON tn.NhomID =  tgvl.LopID AND tn.NienKhoa = tgvl.NienKhoa --and tn.IsNhomLMS_GiaoBai = 0
          INNER JOIN dbo.tblMonHoc      tmh ON tgvl.MonHocID   = tmh.MonHocID AND tmh.Enable = 1
          INNER JOIN dbo.tblKhoi        tk ON tk.KhoiID        = tgvl.KhoiID AND tk.Enable = 1
       
	ORDER BY tgv.GiaoVienID;

END;
