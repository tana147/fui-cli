
--[dbo].[spAPI_KhenThuong_Upd]
--@JsonData = '[
--  {
--    "KhoiID": 1,
--    "TenKhoiHoc": "Khối 1",
--    "CapID": 1,
--    "SoQuyetDinhKT": "17",
--    "NgayKhenThuong_VI": "Ngày 13 tháng 5 năm 2024",
--    "NgayKhenThuong_EN": "May 13th, 2024",
--    "NienKhoa": 2024
--  },
--  {
--    "KhoiID": 2,
--    "TenKhoiHoc": "Khối 2",
--    "CapID": 1,
--    "SoQuyetDinhKT": "17",
--    "NgayKhenThuong_VI": "Ngày 13 tháng 5 năm 2024",
--    "NgayKhenThuong_EN": "May 13th, 2024",
--    "NienKhoa": 2024
--  },
--  {
--    "KhoiID": 3,
--    "TenKhoiHoc": "Khối 3",
--    "CapID": 1,
--    "SoQuyetDinhKT": "17",
--    "NgayKhenThuong_VI": "Ngày 13 tháng 5 năm 2024",
--    "NgayKhenThuong_EN": "May 13th, 2024",
--    "NienKhoa": 2024
--  },
--  {
--    "KhoiID": 4,
--    "TenKhoiHoc": "Khối 4",
--    "CapID": 1,
--    "SoQuyetDinhKT": "17",
--    "NgayKhenThuong_VI": "Ngày 13 tháng 5 năm 2024",
--    "NgayKhenThuong_EN": "May 13th, 2024",
--    "NienKhoa": 2024
--  },
--  {
--    "KhoiID": 5,
--    "TenKhoiHoc": "Khối 5",
--    "CapID": 1,
--    "SoQuyetDinhKT": "17",
--    "NgayKhenThuong_VI": "Ngày 13 tháng 5 năm 2024",
--    "NgayKhenThuong_EN": "May 13th, 2024",
--    "NienKhoa": 2024
--  }
--]',
--@SYS_USERID = 'NA0000022'
CREATE PROC [dbo].[spAPI_KhenThuong_Upd]
    @JsonData   NVARCHAR(MAX)
  , @SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @Table_KhenThuong TABLE
    (
        KhoiID            INT
      , NienKhoa          INT
      , SoQuyetDinhKT     NVARCHAR(50)
      , NgayKhenThuong_VI NVARCHAR(100)
      , NgayKhenThuong_EN NVARCHAR(100)
	  , NgayKhenThuong_ThuKhen_VI NVARCHAR(100)
      , NgayKhenThuong_ThuKhen_EN NVARCHAR(100)
    );
    INSERT INTO @Table_KhenThuong
    (
        KhoiID
      , NienKhoa
      , SoQuyetDinhKT
      , NgayKhenThuong_VI
      , NgayKhenThuong_EN
	   , NgayKhenThuong_ThuKhen_VI  
      , NgayKhenThuong_ThuKhen_EN   
    )
    SELECT *
    FROM
           OPENJSON(@JsonData)
           WITH
           (
               KhoiID INT
             , NienKhoa INT
             , SoQuyetDinhKT NVARCHAR(50)
             , NgayKhenThuong_VI NVARCHAR(100)
             , NgayKhenThuong_EN NVARCHAR(100)
			 , NgayKhenThuong_ThuKhen_VI NVARCHAR(100)
      , NgayKhenThuong_ThuKhen_EN NVARCHAR(100)
           );

    UPDATE kt
    SET    kt.SoQuyetDinhKT = t.SoQuyetDinhKT 
         , kt.NgayKhenThuong_VI = t.NgayKhenThuong_VI 
         , kt.NgayKhenThuong_EN = t.NgayKhenThuong_EN
		 , kt.NgayKhenThuong_ThuKhen_VI = t.NgayKhenThuong_ThuKhen_VI 
         , kt.NgayKhenThuong_ThuKhen_EN = t.NgayKhenThuong_ThuKhen_EN
         , kt.UpdateUser = @SYS_USERID
         , kt.UpdateTime = GETDATE()
    FROM
           dbo.tblKhenThuong            kt
           INNER JOIN @Table_KhenThuong AS t ON t.KhoiID   = kt.KhoiID
                                            AND t.NienKhoa = kt.NienKhoa
    WHERE
           ISNULL(kt.DanhHieu, '') <> '';
END;