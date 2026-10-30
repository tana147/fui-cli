-- spAPI_KhenThuong_SoQD_Get_ByCapID  2024
CREATE PROC [dbo].[spAPI_KhenThuong_SoQD_Get] @NienKhoa INT
AS
BEGIN
    -- Bảng ánh xạ CapID - KhoiID
    DECLARE @CapKhoi TABLE
    (
        CapID  INT
      , KhoiID INT
    );
    INSERT INTO @CapKhoi
    (
        CapID
      , KhoiID
    )
    VALUES
    (
        1
      , 1
    )
  , (
        2
      , 6
    )
  , (
        3
      , 10
    );

    -- Lấy dữ liệu từ tblKhenThuong dựa trên KhoiID
    SELECT DISTINCT
           ck.CapID
         , ck.KhoiID
         , kt.SoQuyetDinhKT
         , kt.NgayKhenThuong_VI
         , kt.NgayKhenThuong_EN
		 , kt.NgayKhenThuong_ThuKhen_VI
         , kt.NgayKhenThuong_ThuKhen_EN
    FROM
           dbo.tblKhenThuong kt
           JOIN @CapKhoi     ck ON kt.KhoiID = ck.KhoiID
    WHERE
           ISNULL(kt.SoQuyetDinhKT, '')    <> ''
		and (
			( ISNULL(kt.NgayKhenThuong_VI, '') <> ''  and ISNULL(kt.NgayKhenThuong_EN, '') <> '' )
			or	( ISNULL(kt.NgayKhenThuong_ThuKhen_VI, '') <> '' AND  ISNULL(kt.NgayKhenThuong_ThuKhen_EN, '') <> ''
		)
	  )
      AND  kt.NienKhoa                      = @NienKhoa;
END;