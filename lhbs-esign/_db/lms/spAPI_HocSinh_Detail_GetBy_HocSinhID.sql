--[dbo].[spAPI_HocSinh_Detail_GetBy_HocSinhID]  19200007, 2023
CREATE   PROC [dbo].[spAPI_HocSinh_Detail_GetBy_HocSinhID]
    @HocSinhID INT
  , @NienKhoa  INT
AS
BEGIN

    DECLARE @CapID INT = 0;

    SELECT TOP 1 @CapID = l.CapID
    FROM
           dbo.tblHocSinhLop         AS hsl
           INNER JOIN dbo.tblHocSinh AS hs ON hs.HocSinhID = hsl.HocSinhID
                                          AND hs.TinhTrang = 0
           INNER JOIN dbo.tblLop     l ON l.LopID          = hsl.LopID
                                      AND l.NienKhoa       = hsl.NienKhoa
                                      AND l.NienKhoa       = @NienKhoa
                                      AND l.Enable         = 1
    WHERE
           hsl.HocSinhID = @HocSinhID
      AND  hsl.Enable    = 1;



    IF (@CapID = 3)
    BEGIN
        SELECT TOP 1
               convert_to_object     = ''
             , hs.HocSinhID
             , hs.Ho + N' ' + hs.Ten AS HoTen
             , hs.NgaySinh
             , hs.Nu
             , hsl.HSLopID
             , hsl.LopID
             , l.NienKhoa
             , l.TenLop
             , l.KhoiID
             , l.CapID
             , n.TenNhom             AS TenLopAV
             , (
                   SELECT b.NienKhoa
                        , b.TenLop
                        , CASE
                               WHEN b.NienKhoa =
                               (
                                   SELECT NienKhoa
                                   FROM
                                          dbo.tblNienKhoa
                                   WHERE
                                          IsActive = 1
                               ) THEN CAST(1 AS BIT)
                               ELSE CAST(0 AS BIT)
                          END AS IsActive
                   FROM
                          dbo.tblHocSinhLop     a
                          INNER JOIN dbo.tblLop b ON b.LopID     = a.LopID
                                                 AND b.NienKhoa  = a.NienKhoa
                                                 AND b.Enable    = 1
                   WHERE
                          a.HocSinhID = @HocSinhID
                     AND  a.Enable     = 1
                   ORDER BY b.NienKhoa
                   FOR JSON PATH
               )                     AS NienKhoaHoc
              , (
                   SELECT n.TenNhom
                        , mh.TenMonHoc_HienThi
                   FROM
                          dbo.tblHocSinhNhom       hsn
                          INNER JOIN dbo.tblNhom   n ON n.NhomID     = hsn.NhomID
                                                    AND n.Enable     = 1
                                                    AND n.NienKhoa   = @NienKhoa
                          INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = n.MonHocID
                                                     AND mh.Enable   = 1
                   WHERE
                          HocSinhID = @HocSinhID
                   FOR JSON PATH
               )                     AS DSNhomDangHoc
        FROM
               dbo.tblHocSinh               AS hs
               INNER JOIN dbo.tblHocSinhLop AS hsl ON hsl.HocSinhID = hs.HocSinhID
                                                  AND hsl.Enable    = 1
               INNER JOIN tblLop            l ON l.LopID            = hsl.LopID
                                             AND l.NienKhoa         = hsl.NienKhoa
                                             AND l.NienKhoa         = @NienKhoa
                                             AND l.Enable           = 1
               LEFT JOIN dbo.tblHocSinhNhom AS hsn ON hsn.HocSinhID = hs.HocSinhID
                                                  AND hsn.Enable    = 1
               LEFT JOIN dbo.tblNhom        AS n ON n.NhomID        = hsn.NhomID
                                                AND n.Enable        = 1
                                                AND n.NienKhoa      = @NienKhoa
        WHERE
               hs.HocSinhID = @HocSinhID
          AND  hs.TinhTrang  = 0;


    END;
    ELSE
    BEGIN
        SELECT TOP 1
               convert_to_object     = ''
             , hs.HocSinhID
             , hs.Ho + N' ' + hs.Ten AS HoTen
             , hs.NgaySinh
             , hs.Nu
             , hsl.LopID
             , hsl.HSLopID
             , l.NienKhoa
             , l.TenLop
             , l.KhoiID
             , l.CapID
             , (
                   SELECT b.NienKhoa
                        , b.TenLop
                        , CASE
                               WHEN b.NienKhoa =
                               (
                                   SELECT NienKhoa
                                   FROM
                                          dbo.tblNienKhoa
                                   WHERE
                                          IsActive = 1
                               ) THEN CAST(1 AS BIT)
                               ELSE CAST(0 AS BIT)
                          END AS IsActive
                   FROM
                          dbo.tblHocSinhLop     a
                          INNER JOIN dbo.tblLop b ON b.LopID     = a.LopID
                                                 AND b.NienKhoa  = a.NienKhoa
                                                 AND b.Enable    = 1
                   WHERE
                          a.HocSinhID = @HocSinhID
                     AND  a.Enable     = 1
                   ORDER BY b.NienKhoa
                   FOR JSON PATH
               )                     AS NienKhoaHoc
             , (
                   SELECT n.TenNhom
                        , mh.TenMonHoc_HienThi
                   FROM
                          dbo.tblHocSinhNhom       hsn
                          INNER JOIN dbo.tblNhom   n ON n.NhomID     = hsn.NhomID
                                                    AND n.Enable     = 1
                                                    AND n.NienKhoa   = @NienKhoa
                          INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = n.MonHocID
                                                     AND mh.Enable   = 1
                   WHERE
                          HocSinhID = @HocSinhID
                   FOR JSON PATH
               )                     AS DSNhomDangHoc
        FROM
               dbo.tblHocSinhLop         AS hsl
               INNER JOIN dbo.tblHocSinh AS hs ON hsl.HocSinhID = hs.HocSinhID
                                              AND hs.HocSinhID  = @HocSinhID
                                              AND hs.TinhTrang  = 0
               INNER JOIN dbo.tblLop     AS l ON l.LopID        = hsl.LopID
                                             AND l.NienKhoa     = hsl.NienKhoa
                                             AND l.NienKhoa     = @NienKhoa
                                             AND l.Enable       = 1
        WHERE
               hsl.Enable = 1;
    END;

END;



