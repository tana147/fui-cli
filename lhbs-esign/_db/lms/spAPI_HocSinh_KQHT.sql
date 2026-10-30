-- spAPI_HocSinh_KQHT 21000026, 2362
CREATE PROC [dbo].[spAPI_HocSinh_KQHT]
    @HocSinhID VARCHAR(9)
  , @LopNhom   NVARCHAR(50)
  , @Semester  VARCHAR(10)
  , @NienKhoa INT
AS
BEGIN
    DECLARE @CapID INT = 0;
    SELECT @CapID = l.CapID
    FROM
           dbo.tblHocSinhLop     hsl
           INNER JOIN dbo.tblLop l ON l.LopID  = hsl.LopID AND l.NienKhoa = @NienKhoa
                                  AND l.Enable = 1
    AND hsl.NienKhoa = l.NienKhoa
        WHERE
           hsl.LopID    = @LopNhom
      AND  hsl.HocSinhID = @HocSinhID;

    DECLARE @MonHocLopID INT = 0;
    DECLARE @LopNhomID VARCHAR(20) = '';
    SELECT TOP 1
           @MonHocLopID = kqht.MonHocLopID
         , @LopNhomID   = kqht.LopID
    FROM
           dbo.tblKetQuaHocTap         kqht
           INNER JOIN dbo.tblMonHocLop mhl ON mhl.MonHocLopID = kqht.MonHocLopID
                                          AND mhl.ChiaTheoLop = 0
    WHERE
           kqht.HocSinhID = @HocSinhID;

    SELECT T.MonHocID
         , T.MonHocCode
         , T.MonHocName
         , T.MonHocGroup
         , T.TrangThai
         , T.MaMonDuLieuNganh
         , T.TenMonDuLieuNganh
         , T.Color
    FROM
           (
               SELECT mh.MonHocID
                    , mh.MonHocCode
                    , mh.MonHocName
                    , mh.MonHocGroup
                    , mh.TrangThai
                    , mh.MaMonDuLieuNganh
                    , mh.TenMonDuLieuNganh
                    , mh.Color
               FROM
                      dbo.tblMonHocLop         mhl
                      INNER JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
                                                 AND mh.Enable    = 1
               WHERE
                      mhl.LopNhomID = @LopNhom
                 AND  mhl.Enable     = 1
               UNION
               SELECT mh.MonHocID
                    , mh.MonHocCode
                    , mh.MonHocName
                    , mh.MonHocGroup
                    , mh.TrangThai
                    , mh.MaMonDuLieuNganh
                    , mh.TenMonDuLieuNganh
                    , mh.Color
               FROM
                      dbo.tblMonHocLop         mhl
                      INNER JOIN dbo.tblMonHoc mh ON mhl.MonHocID = mh.MonHocID
                                                 AND mh.Enable    = 1
               WHERE
                      mhl.MonHocLopID = @MonHocLopID
                 AND  mhl.Enable       = 1
           ) AS T
    ORDER BY
           T.MonHocID;

    --LẤY RA KQHT
    SELECT T.MonHocID
         , T.MonHocCode
         , T.MonHocGroup
         , T.MonHocName
         --, T.LoaiCotDiem
         , T.IDHeThong
         , T.MaCotDiem
         , T.TenCotDiem_VI
         , T.TenCotDiem_EN
         , T.TenHienThi_VI
         , T.TenHienThi_EN
         , T.MotaCotDiem_VI
         , T.MotaCotDiem_EN
         , T.LoaiCotDiem
         , T.KieuDanhGiaID
         , T.GiaTriCotDiem
         , T.LamTronBaoNhieuSo
         , T.DiemMin
         , T.DiemMax
         , T.Formula
         , T.ThuTuCotDiem
         , T.MaNhomCotDiem
         , T.TenNhomCotDiem_VI
         , T.TenNhomCotDiem_EN
         , T.ThuTuNhom
         , T.IsUserInput
         , T.IsVisibleToParents
         , T.IsSendToManager
         , T.CssClass
         , T.HexBackground
         , T.Semester
         , T.CotDiemID
         , T.KetQuaDanhGia_VI
         , T.KetQuaDanhGia_EN
         , T.Color
    FROM
           (
               SELECT mh.MonHocID
                    , mh.MonHocCode
                    , mh.MonHocGroup
                    , mh.MonHocName
                    --, tbd_dt.LoaiCotDiem
                    , tbd_dt.IDHeThong
                    , tbd_dt.MaCotDiem
                    , tbd_dt.TenCotDiem_VI
                    , tbd_dt.TenCotDiem_EN
                    , tbd_dt.TenHienThi_VI
                    , tbd_dt.TenHienThi_EN
                    , tbd_dt.MotaCotDiem_VI
                    , tbd_dt.MotaCotDiem_EN
                    , tbd_dt.LoaiCotDiem
                    , tbd_dt.KieuDanhGiaID
                    , tbd_dt.GiaTriCotDiem
                    , tbd_dt.LamTronBaoNhieuSo
                    , tbd_dt.DiemMin
                    , tbd_dt.DiemMax
                    , tbd_dt.Formula
                    , tbd_dt.ThuTuCotDiem
                    , tbd_dt.MaNhomCotDiem
                    , tbd_dt.TenNhomCotDiem_VI
                    , tbd_dt.TenNhomCotDiem_EN
                    , tbd_dt.ThuTuNhom
                    , tbd_dt.IsUserInput
                    , tbd_dt.IsVisibleToParents
                    , tbd_dt.IsSendToManager
                    , tbd_dt.CssClass
                    , tbd_dt.HexBackground
                    , tbd_dt.Semester
                    , kq.CotDiemID
                    , kq.KetQuaDanhGia_VI
                    , kq.KetQuaDanhGia_EN
                    , mh.Color
               FROM
                      dbo.tblMonHoc                          mh
                      INNER JOIN dbo.tblMonHocLop            mhl ON mh.MonHocID                  = mhl.MonHocID
                                                                AND mhl.Enable                   = 1
                                                                AND mhl.NienKhoa                 = @NienKhoa
                      INNER JOIN dbo.TemplateBangDiem        tbd ON tbd.TemplateBangDiemID       = mhl.TemplateBangDiemID
                                                                AND tbd.NienKhoa                 = @NienKhoa
                                                                AND tbd.Enable                   = 1
                      INNER JOIN dbo.TemplateBangDiemChiTiet tbd_dt ON tbd_dt.TemplateBangDiemID = tbd.TemplateBangDiemID
                                                                   AND tbd_dt.IsVisibleToParents = 1
                                                                   AND tbd_dt.Enable             = 1
                      INNER JOIN dbo.tblKetQuaHocTap         kq ON kq.CotDiemID                  = tbd_dt.CotDiemID
                                                               AND
                                                                   (
                                                                       kq.KetQuaDanhGia_VI IS NOT NULL
                                                                  OR   kq.KetQuaDanhGia_EN IS NOT NULL
                                                                   )
                                                               AND kq.Enable                     = 1
               WHERE
                      mhl.LopNhomID  = @LopNhom
                 AND  kq.HocSinhID    = @HocSinhID
                 AND  tbd_dt.Semester = @Semester
               UNION
               SELECT mh.MonHocID
                    , mh.MonHocCode
                    , mh.MonHocGroup
                    , mh.MonHocName
                    --, tbd_dt.LoaiCotDiem
                    , tbd_dt.IDHeThong
                    , tbd_dt.MaCotDiem
                    , tbd_dt.TenCotDiem_VI
                    , tbd_dt.TenCotDiem_EN
                    , tbd_dt.TenHienThi_VI
                    , tbd_dt.TenHienThi_EN
                    , tbd_dt.MotaCotDiem_VI
                    , tbd_dt.MotaCotDiem_EN
                    , tbd_dt.LoaiCotDiem
                    , tbd_dt.KieuDanhGiaID
                    , tbd_dt.GiaTriCotDiem
                    , tbd_dt.LamTronBaoNhieuSo
                    , tbd_dt.DiemMin
                    , tbd_dt.DiemMax
                    , tbd_dt.Formula
                    , tbd_dt.ThuTuCotDiem
                    , tbd_dt.MaNhomCotDiem
                    , tbd_dt.TenNhomCotDiem_VI
                    , tbd_dt.TenNhomCotDiem_EN
                    , tbd_dt.ThuTuNhom
                    , tbd_dt.IsUserInput
                    , tbd_dt.IsVisibleToParents
                    , tbd_dt.IsSendToManager
                    , tbd_dt.CssClass
                    , tbd_dt.HexBackground
                    , tbd_dt.Semester
                    , kq.CotDiemID
                    , kq.KetQuaDanhGia_VI
                    , kq.KetQuaDanhGia_EN
                    , mh.Color
               FROM
                      dbo.tblMonHoc                          mh
                      INNER JOIN dbo.tblMonHocLop            mhl ON mh.MonHocID                  = mhl.MonHocID
                                                                AND mhl.Enable                   = 1
                      INNER JOIN dbo.TemplateBangDiem        tbd ON tbd.TemplateBangDiemID       = mhl.TemplateBangDiemID
                                                                AND tbd.Enable                   = 1
                      INNER JOIN dbo.TemplateBangDiemChiTiet tbd_dt ON tbd_dt.TemplateBangDiemID = tbd.TemplateBangDiemID
                                                                   AND tbd_dt.IsVisibleToParents = 1
                                                                   AND tbd_dt.Enable             = 1
                                                                   AND tbd_dt.Semester           = @Semester
                      INNER JOIN dbo.tblKetQuaHocTap         kq ON kq.CotDiemID                  = tbd_dt.CotDiemID
                                                               AND
                                                                   (
                                                                       kq.KetQuaDanhGia_VI IS NOT NULL
                                                                  OR   kq.KetQuaDanhGia_EN IS NOT NULL
                                                                   )
                                                               AND kq.Enable                     = 1
                                                               AND kq.HocSinhID                  = @HocSinhID
               WHERE
                      mhl.LopNhomID  = @LopNhomID
                 AND  kq.HocSinhID    = @HocSinhID
                 AND  tbd_dt.Semester = @Semester
           ) AS T
    ORDER BY
           T.MonHocID
         , T.ThuTuNhom
         , T.ThuTuCotDiem;
END;