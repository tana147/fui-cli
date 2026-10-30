CREATE PROC [dbo].[spAPI_KhenThuong_Ins]
    @Json_KhenThuong NVARCHAR(MAX)
  , @SYS_USERID      VARCHAR(9)
AS
BEGIN
    DECLARE @Table_KhenThuong TABLE
    (
        NienKhoa          INT
      , HSLopID           INT
      , HocSinhTieuBieu   BIT
      , NoiDungThuKhen    NVARCHAR(2000)
      , ThanhTichKhac     NVARCHAR(4000)
      , DanhHieu          NVARCHAR(1000)
      , VaoSoKT           INT
      , SoQuyetDinhKT     NVARCHAR(50)
      , NgayKhenThuong_VI NVARCHAR(100)
      , NgayKhenThuong_EN NVARCHAR(100)
	  , NgayKhenThuong_ThuKhen_VI	 NVARCHAR(100)
	  , NgayKhenThuong_ThuKhen_EN	 NVARCHAR(100)

    );

    INSERT INTO @Table_KhenThuong
    (
        NienKhoa
      , HSLopID
      , HocSinhTieuBieu
      , NoiDungThuKhen
      , ThanhTichKhac
      , DanhHieu
      , VaoSoKT
      , SoQuyetDinhKT
      , NgayKhenThuong_VI
      , NgayKhenThuong_EN
	  , NgayKhenThuong_ThuKhen_VI	  
	  , NgayKhenThuong_ThuKhen_EN	  
    )
    SELECT NienKhoa
         , HSLopID
         , HocSinhTieuBieu
         , NoiDungThuKhen
         , ThanhTichKhac
         , DanhHieu
         , VaoSoKT
         , SoQuyetDinhKT
         , NgayKhenThuong_VI
         , NgayKhenThuong_EN
		 , NgayKhenThuong_ThuKhen_VI 
	  , NgayKhenThuong_ThuKhen_EN	 
    FROM
           OPENJSON(@Json_KhenThuong)
           WITH
           (
               NienKhoa INT
             , HSLopID INT
             , HocSinhTieuBieu BIT
             , NoiDungThuKhen NVARCHAR(2000)
             , ThanhTichKhac NVARCHAR(4000)
             , DanhHieu NVARCHAR(1000)
             , VaoSoKT INT
             , SoQuyetDinhKT NVARCHAR(50)
             , NgayKhenThuong_VI NVARCHAR(100)
             , NgayKhenThuong_EN NVARCHAR(100)
			 , NgayKhenThuong_ThuKhen_VI	 NVARCHAR(100)
	  , NgayKhenThuong_ThuKhen_EN	 NVARCHAR(100)
           );

    UPDATE kt
    SET    kt.HocSinhTieuBieu		= ISNULL(t.HocSinhTieuBieu		,kt.HocSinhTieuBieu		)
         , kt.NoiDungThuKhen		= ISNULL(t.NoiDungThuKhen		,kt.NoiDungThuKhen		)
         , kt.ThanhTichKhac			= ISNULL(t.ThanhTichKhac		,kt.ThanhTichKhac		)
         , kt.DanhHieu				= ISNULL(t.DanhHieu				,kt.DanhHieu			)
         , kt.VaoSoKT				= ISNULL(t.VaoSoKT				,kt.VaoSoKT				)
         , kt.SoQuyetDinhKT			= ISNULL(t.SoQuyetDinhKT		,kt.SoQuyetDinhKT		)
         , kt.NgayKhenThuong_VI		= ISNULL(t.NgayKhenThuong_VI	,kt.NgayKhenThuong_VI	)
         , kt.NgayKhenThuong_EN		= ISNULL(t.NgayKhenThuong_EN	,kt.NgayKhenThuong_EN	)
		 ,  kt.NgayKhenThuong_ThuKhen_VI = ISNULL(t.NgayKhenThuong_ThuKhen_VI 	,kt.NgayKhenThuong_ThuKhen_VI 	)
		 ,  kt.NgayKhenThuong_ThuKhen_EN = ISNULL(t.NgayKhenThuong_ThuKhen_EN 	,kt.NgayKhenThuong_ThuKhen_EN 	)
         , kt.UpdateUser = @SYS_USERID
         , kt.UpdateTime = GETDATE()
    FROM
           dbo.tblKhenThuong            AS kt
           INNER JOIN @Table_KhenThuong t ON t.NienKhoa = kt.NienKhoa
                                         AND t.HSLopID  = kt.HSLopID

    INSERT INTO dbo.tblKhenThuong
    (
        NienKhoa
      , KhoiID
      , HSLopID
      , HocSinhTieuBieu
      , NoiDungThuKhen
      , ThanhTichKhac
      , DanhHieu
      , VaoSoKT
      , SoQuyetDinhKT
      , NgayKhenThuong_VI
      , NgayKhenThuong_EN
	 ,  NgayKhenThuong_ThuKhen_VI 
	 ,  NgayKhenThuong_ThuKhen_EN 
      , Enable
      , CreateUser
      , CreateTime
    )
    SELECT t.NienKhoa
		 , l.KhoiID
         , t.HSLopID
         , t.HocSinhTieuBieu
         , t.NoiDungThuKhen
         , t.ThanhTichKhac
         , t.DanhHieu
         , t.VaoSoKT
         , t.SoQuyetDinhKT
         , t.NgayKhenThuong_VI
         , t.NgayKhenThuong_EN
		 , t.NgayKhenThuong_ThuKhen_VI 
		 , t.NgayKhenThuong_ThuKhen_EN 
         , 1
         , @SYS_USERID
         , GETDATE()
    FROM
           @Table_KhenThuong AS t
		   INNER JOIN dbo.tblHocSinhLop AS hsl ON hsl.HSLopID = t.HSLopID AND hsl.Enable = 1
		   INNER JOIN dbo.tblLop AS l ON l.LopID = hsl.LopID AND l.Enable = 1 AND l.NienKhoa = t.NienKhoa
    AND hsl.NienKhoa = l.NienKhoa
        WHERE
           NOT EXISTS
    (
        SELECT *
        FROM
               dbo.tblKhenThuong AS kt
        WHERE
               t.NienKhoa = kt.NienKhoa
          AND  t.HSLopID   = kt.HSLopID
    ); 
END;