-- [dbo].[spAPI_MonHocLop_CapID_Get]   2
CREATE PROC [dbo].[spAPI_MonHocLop_CapID_Get]
    @CapID    INT
  , @NienKhoa INT
AS
BEGIN
    SELECT mhl.LopNhomID
         , l.TenLop
         , mh.MonHocCode
         , mh.MonHocName
         , mhl.MonHocLopID
         , mhl.TemplateBangDiemID
    FROM
           dbo.tblMonHocLop         mhl
           INNER JOIN dbo.tblLop    l ON l.LopID      = mhl.LopNhomID AND l.NienKhoa = @NienKhoa
                                     AND l.Enable     = 1
           INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = mhl.MonHocID
                                      AND mh.Enable   = 1
    WHERE
           mh.CapID    = @CapID
      AND  l.CapID      = @CapID
      AND  mhl.NienKhoa = @NienKhoa
      AND  mhl.Enable   = 1
    ORDER BY
           mhl.LopNhomID
         , mh.Sort;
END;