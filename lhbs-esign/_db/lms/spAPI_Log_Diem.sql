CREATE PROC [dbo].[spAPI_Log_Diem]
@NienKhoa int,
    @LopID         VARCHAR(10)
  , @MonHocID      INT
  , @MaNhomCotDiem VARCHAR(100)
  , @HocSinhID     INT
AS
BEGIN

    DECLARE @MonHocLopID INT = 0;
    SELECT @MonHocLopID = mhl.MonHocLopID
    FROM dbo.tblMonHocLop AS mhl
    INNER JOIN dbo.tblLop AS lop
        ON lop.LopID = mhl.LopNhomID
       AND lop.NienKhoa = mhl.NienKhoa
    WHERE mhl.LopNhomID = @LopID
      AND mhl.NienKhoa = @NienKhoa
      AND mhl.MonHocID = @MonHocID;


    DECLARE @Table_Log TABLE
    (
        KQHTID                  INT
      , MonHocLopID             INT
      , HocSinhID               INT
      , LopID                   VARCHAR(10)
      , NienKhoa                INT
      , CotDiemID               INT
      , KetQuaDanhGia_VI        NVARCHAR(1000)
      , KetQuaDanhGia_EN        NVARCHAR(1000)
      , Lop_TinhTrangID         INT
      , TinhTrang               TINYINT
      , Enable                  BIT
      , CreateUser              VARCHAR(20)
      , CreateTime              DATETIME
      , UpdateUser              VARCHAR(20)
      , UpdateTime              DATETIME
      , NhapDiemUser            VARCHAR(9)
      , NhapDiemTime            DATETIME 
    );
    INSERT INTO @Table_Log
    (
        KQHTID
      , MonHocLopID
      , HocSinhID
      , LopID
      , NienKhoa
      , CotDiemID
      , KetQuaDanhGia_VI
      , KetQuaDanhGia_EN
      , Lop_TinhTrangID
      , TinhTrang
      , Enable
      , CreateUser
      , CreateTime
      , UpdateUser
      , UpdateTime
      , NhapDiemUser
      , NhapDiemTime
    )
    SELECT kqht.KQHTID
         , kqht.MonHocLopID
         , kqht.HocSinhID
         , kqht.LopID
         , kqht.NienKhoa
         , kqht.CotDiemID
         , kqht.KetQuaDanhGia_VI
         , kqht.KetQuaDanhGia_EN
         , kqht.Lop_TinhTrangID
         , kqht.TinhTrang
         , kqht.Enable
         , kqht.CreateUser
         , kqht.CreateTime
         , kqht.UpdateUser
         , kqht.UpdateTime
         , kqht.NhapDiemUser
         , kqht.NhapDiemTime
      
    FROM
           dbo.tbl_LOG_KetQuaHocTap AS kqht
    WHERE
           kqht.MonHocLopID = @MonHocLopID
      -- NULL HocSinhID returns class-wide history; a value preserves the existing per-student API behavior.
      AND  (@HocSinhID IS NULL OR kqht.HocSinhID = @HocSinhID)
      AND  kqht.NienKhoa     = @NienKhoa
      -- This is a filter only; EXISTS prevents duplicate active template rows multiplying a log entry.
      AND EXISTS (
              SELECT 1
              FROM dbo.TemplateBangDiemChiTiet AS columnTemplate
              WHERE columnTemplate.CotDiemID = kqht.CotDiemID
                AND columnTemplate.Enable = 1
          );

    SELECT t_l.KQHTID
         , l_tt.MonHocLopID
         , t_l.HocSinhID
         , t_l.LopID
         , t_l.NienKhoa
         , t_l.CotDiemID
         , t_l.KetQuaDanhGia_VI
         , t_l.KetQuaDanhGia_EN
         , t_l.Lop_TinhTrangID
         , t_l.NhapDiemUser
         , FORMAT(t_l.NhapDiemTime, 'dd/MM/yyyy HH:mm:ss.fff') AS NhapDiemTime
         , l_tt.TinhTrang
         , l_tt.NoiDungNhanXet
         , ISNULL(l_tt.TinhTrang, 0)                       AS TinhTrang
         , dbo.RenderTinhTrang(l_tt.TinhTrang)             AS TenTinhTrang
         , dbo.RenderColorTinhTrang(l_tt.TinhTrang)        AS MauTinhTrang
         , l_tt.MaNhomCotDiem
         , tbdct.MaCotDiem
         , mh.TenMonHoc_HienThi
         , l_tt.CreateUser
         , l_tt.CreateTime
         , l_tt.UpdateUser
         , l_tt.UpdateTime
         , hs.Ho
         , hs.Ten
         , hs.Ho + ' ' + hs.Ten                            AS HoTen
         , hs.NgaySinh
         , hs.Nu
         , hsl.SoDanhBo
    FROM
           @Table_Log                             AS t_l
           OUTER APPLY (
               SELECT MAX(columnTemplate.MaCotDiem) AS MaCotDiem
               FROM dbo.TemplateBangDiemChiTiet AS columnTemplate
               WHERE columnTemplate.CotDiemID = t_l.CotDiemID
                 AND columnTemplate.Enable = 1
           ) AS tbdct
           INNER JOIN dbo.tblLop_TinhTrang        AS l_tt ON l_tt.Lop_TinhTrangID = t_l.Lop_TinhTrangID
           INNER JOIN dbo.tblMonHocLop            mhl ON mhl.MonHocLopID          = @MonHocLopID
           INNER JOIN dbo.tblMonHoc               mh ON mh.MonHocID               = mhl.MonHocID
                                                    AND mh.Enable                 = 1
           INNER JOIN dbo.tblHocSinh              AS hs ON hs.HocSinhID           = t_l.HocSinhID
           -- Match active membership by the full class key; LopID is reused across school years.
           LEFT JOIN (
               SELECT HocSinhID, LopID, NienKhoa, MAX(SoDanhBo) AS SoDanhBo
               FROM dbo.tblHocSinhLop
               WHERE Enable = 1
               GROUP BY HocSinhID, LopID, NienKhoa
           ) AS hsl ON hsl.HocSinhID = hs.HocSinhID
                   AND hsl.LopID = t_l.LopID
                   AND hsl.NienKhoa = t_l.NienKhoa
    ORDER BY
           1 DESC;
END;
