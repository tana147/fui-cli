CREATE PROC [dbo].[spAPI_NhanXetThang_Template_Get]
    @LopID              INT
  , @Lop_NhanXetThangID INT
AS
BEGIN
    DECLARE @Table_HocSinh TABLE
    (
        HocSinhID    INT
      , HSLopID      INT
      , SoDanhBo     VARCHAR(20)
      , Ho           NVARCHAR(200)
      , Ten          NVARCHAR(50)
      , HoTen        NVARCHAR(500)
      , NgaySinh     VARCHAR(10)
      , Nu           BIT
      , TinhTrang    TINYINT
      , TenTinhTrang NVARCHAR(100)
    );

    INSERT INTO @Table_HocSinh
    (
        HocSinhID
      , HSLopID
      , SoDanhBo
      , Ho
      , Ten
      , HoTen
      , NgaySinh
      , Nu
      , TinhTrang
      , TenTinhTrang
    )
    EXEC dbo.spAPI_HocSinhLop_Get_ByLopID @LopID = @LopID;


    SELECT t_hs.HocSinhID
         , t_hs.HSLopID
         , t_hs.SoDanhBo
         , t_hs.Ho
         , t_hs.Ten
         , t_hs.HoTen
         , t_hs.NgaySinh
         , t_hs.Nu
         , nxt.NoiDungNangLuc_HTML
         , nxt.NoiDungKienThuc_HTML
         , nxt.NoiDungHoatDongKhac_HTML
    FROM
           @Table_HocSinh                    AS t_hs
           LEFT JOIN dbo.tblNhanXetThang     AS nxt ON t_hs.HocSinhID             = nxt.HocSinhID
                                                   AND nxt.Lop_NhanXetThangID   = @Lop_NhanXetThangID
                                                   AND nxt.Enable                 = 1
           LEFT JOIN dbo.tblNhanXetThang_Lop AS l_nxt ON l_nxt.Lop_NhanXetThangID = nxt.Lop_NhanXetThangID
                                                     AND l_nxt.Enable             = 1
    WHERE
           t_hs.TinhTrang = 0;

END;

