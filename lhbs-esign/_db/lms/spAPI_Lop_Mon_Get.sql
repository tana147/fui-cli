CREATE PROC [dbo].[spAPI_Lop_Mon_Get]
    @SYS_USERID      VARCHAR(9)
  , @sys_SystemRight INT
AS
BEGIN
    SELECT gvl.GVLopID
         , gvl.GiaoVienID
         , gvl.KhoiID
         , gvl.LopID
         , gvl.MonHocID
         , gvl.MaDonVi
         , gvl.VaiTro
         , gvl.NienKhoa
         , gvl.GhiChu
         , mh.MonHocID
         , mh.Sort
         , mh.CapID
         , mh.MonHocCode
         , mh.MonHocName
         , mh.MonHocGroup
         , mh.TrangThai
         , mh.MaMonDuLieuNganh
         , mh.TenMonDuLieuNganh
         , mh.TenMonHoc_HienThi
         , mh.ToGiangDayDayID
         , mh.SoTietHK1
         , mh.SoTietHocKy2
         , mh.SoTuanHK1
         , mh.SoTuanHK2
         , mh.Color
         , mh.Is_MonHoc_BoTro
         , mh.List_MonHoc_NLPC_ID
		 , l.TenLop
    FROM
           dbo.tblGiaoVienLop       AS gvl
           INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = gvl.MonHocID
                                         AND mh.Enable   = 1
           INNER JOIN dbo.tblLop    AS l ON l.LopID      = gvl.LopID AND l.NienKhoa = gvl.NienKhoa
                                        AND l.Enable     = 1
    WHERE
           gvl.GiaoVienID = @SYS_USERID
      AND  gvl.Enable      = 1
	UNION ALL
	 SELECT gvl.GVLopID
         , gvl.GiaoVienID
         , gvl.KhoiID
         , gvl.LopID
         , gvl.MonHocID
         , gvl.MaDonVi
         , gvl.VaiTro
         , gvl.NienKhoa
         , gvl.GhiChu
         , mh.MonHocID
         , mh.Sort
         , mh.CapID
         , mh.MonHocCode
         , mh.MonHocName
         , mh.MonHocGroup
         , mh.TrangThai
         , mh.MaMonDuLieuNganh
         , mh.TenMonDuLieuNganh
         , mh.TenMonHoc_HienThi
         , mh.ToGiangDayDayID
         , mh.SoTietHK1
         , mh.SoTietHocKy2
         , mh.SoTuanHK1
         , mh.SoTuanHK2
         , mh.Color
         , mh.Is_MonHoc_BoTro
         , mh.List_MonHoc_NLPC_ID
		 ,	n.TenNhom AS TenLop
    FROM
           dbo.tblGiaoVienLop       AS gvl
           INNER JOIN dbo.tblMonHoc AS mh ON mh.MonHocID = gvl.MonHocID
                                         AND mh.Enable   = 1
           INNER JOIN dbo.tblNhom    AS n ON	n.NhomID = gvl.LopID
                                        AND		n.Enable = 1
										and n.IsNhomLMS_GiaoBai = 0
    WHERE
           gvl.GiaoVienID = @SYS_USERID
      AND  gvl.Enable      = 1
	ORDER BY gvl.KhoiID, l.TenLop, mh.Sort

END;