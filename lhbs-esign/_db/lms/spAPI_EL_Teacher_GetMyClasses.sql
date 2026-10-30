CREATE PROCEDURE [dbo].[spAPI_EL_Teacher_GetMyClasses]
    @sys_UserID      VARCHAR(9)
  , @sys_SystemRight INT
  , @HocKi           INT
  , @NienKhoa        INT
AS
BEGIN
    SELECT @sys_UserID      = SYS_USERID
         , @sys_SystemRight = SYS_SystemRight
    FROM
           dbo.Table_GetUser_LMS(@sys_UserID, @sys_SystemRight);

    DECLARE @NienKhoa_HienTai INT = @NienKhoa;
    IF (@NienKhoa_HienTai IS NULL OR @NienKhoa_HienTai = 0)
        SET @NienKhoa_HienTai = dbo.fn_GetNienKhoa_HienTai();

    SELECT @NienKhoa_HienTai;
    SELECT *
    FROM
           (
               -- tblGiaoVienLop + tblLop
               SELECT DISTINCT
                      gvl.LopID
                    , l.TenLop
                    , gvl.KhoiID
                    , c.CapID
               FROM
                      dbo.tblGiaoVienLop    gvl
                      JOIN dbo.tblLop       l ON gvl.LopID = l.LopID
                                             AND l.NienKhoa = @NienKhoa_HienTai
                                             AND l.Enable = 1
                      INNER JOIN dbo.tblCap c ON c.CapID   = l.CapID
               WHERE
                      gvl.GiaoVienID = @sys_UserID
                 AND  gvl.NienKhoa    = @NienKhoa_HienTai
                 AND  gvl.Enable      = 1
                 AND  gvl.HocKy       = @HocKi
               UNION

               -- tblGiaoVienLop + tblNhom
               SELECT DISTINCT
                      gvl.LopID
                    , n.TenNhom AS TenLop
                    , gvl.KhoiID
                    , 3         AS CapID
               FROM
                      dbo.tblGiaoVienLop gvl
                      JOIN dbo.tblNhom   n ON gvl.LopID = n.NhomID
                                            AND n.NienKhoa = @NienKhoa_HienTai
                                            AND n.Enable = 1
               WHERE
                      gvl.GiaoVienID = @sys_UserID
                 AND  gvl.NienKhoa    = @NienKhoa_HienTai
                 AND  gvl.Enable      = 1
                 AND  gvl.HocKy       = @HocKi
               UNION

               -- tblEL_GiaoVienLop + tblLop
               SELECT DISTINCT
                      gvl2.LopID
                    , l.TenLop
                    , gvl2.KhoiID
                    , c.CapID
               FROM
                      dbo.tblEL_GiaoVienLop gvl2
                      JOIN dbo.tblLop       l ON gvl2.LopID = l.LopID
                                             AND l.NienKhoa = @NienKhoa_HienTai
                                             AND l.Enable = 1
                      INNER JOIN dbo.tblCap c ON c.CapID    = l.CapID
               WHERE
                      gvl2.GiaoVienID = @sys_UserID
                 AND  gvl2.NienKhoa    = @NienKhoa_HienTai
                 AND  gvl2.Enable      = 1
                 AND  gvl2.HocKy       = @HocKi
               UNION

               -- tblEL_GiaoVienLop + tblNhom
               SELECT DISTINCT
                      gvl2.LopID
                    , n.TenNhom AS TenLop
                    , gvl2.KhoiID
                    , 3         AS CapID
               FROM
                      dbo.tblEL_GiaoVienLop gvl2
                      JOIN dbo.tblNhom      n ON gvl2.LopID = n.NhomID
                                             AND n.NienKhoa = @NienKhoa_HienTai
                                             AND n.Enable = 1
               WHERE
                      gvl2.GiaoVienID = @sys_UserID
                 AND  gvl2.NienKhoa    = @NienKhoa_HienTai
                 AND  gvl2.Enable      = 1
                 AND  gvl2.HocKy       = @HocKi
               UNION
               SELECT mhl.LopNhomID
                    , COALESCE(l.TenLop, n.TenNhom)
                    , COALESCE(l.KhoiID, n.KhoiID)
                    , COALESCE(l.CapID, n.CapID)
               FROM
                      tblEL_Resoucre_TeacherPermissions rtp
                      INNER JOIN tblEL_AssignToClass    atc ON atc.AssignToClassID = rtp.AssignToClassID
                                                           AND atc.IsDeleted       = 0
                      INNER JOIN tblMonHocLop           mhl ON atc.MonHocLopID     = mhl.MonHocLopID
                                                           AND mhl.Enable          = 1
                      LEFT JOIN dbo.tblLop              l ON mhl.LopNhomID         = l.LopID
                                                         AND l.NienKhoa            = @NienKhoa_HienTai
                                                         AND l.Enable              = 1
                      LEFT JOIN dbo.tblNhom             n ON mhl.LopNhomID         = n.NhomID
                                                         AND n.NienKhoa            = @NienKhoa_HienTai
                                                         AND n.Enable              = 1
               WHERE
                      rtp.Enable    = 1
                 AND
                      (
                          rtp.GiaoVienID = @sys_UserID
                     OR   rtp.CreateUser = @sys_UserID
                      )
               UNION

               -- Quyền SUBJECT mở rộng danh sách lớp/nhóm theo môn trong niên khóa.
               -- Không có AssignToClassID nên không thể lấy lớp qua nhánh phân quyền từng bài.
               SELECT DISTINCT
                      mhl.LopNhomID
                    , COALESCE(l.TenLop, n.TenNhom)
                    , COALESCE(l.KhoiID, n.KhoiID)
                    , COALESCE(l.CapID, n.CapID)
               FROM
                      dbo.tblEL_Resoucre_TeacherPermissions rtp
                      INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocID = rtp.MonHocID
                                                     AND mhl.NienKhoa = @NienKhoa_HienTai
                                                     AND mhl.Enable = 1
                      LEFT JOIN dbo.tblLop l ON mhl.LopNhomID = l.LopID
                                             AND l.NienKhoa = @NienKhoa_HienTai
                                             AND l.Enable = 1
                      LEFT JOIN dbo.tblNhom n ON mhl.LopNhomID = n.NhomID
                                              AND n.NienKhoa = @NienKhoa_HienTai
                                              AND n.Enable = 1
               WHERE
                      rtp.Enable = 1
                 AND  rtp.GiaoVienID = @sys_UserID
                 AND  rtp.PermissionScope = 'SUBJECT'
                 AND  (rtp.NienKhoa IS NULL OR rtp.NienKhoa = @NienKhoa_HienTai)
           ) AS t
    WHERE
           t.KhoiID IS NOT NULL
    ORDER BY
           t.TenLop;
END;
