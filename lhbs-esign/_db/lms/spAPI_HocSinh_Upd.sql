CREATE PROC [dbo].[spAPI_HocSinh_Upd]
    @HocSinhID INT
  , @Ho        NVARCHAR(200)
  , @Ten       NVARCHAR(200)
  , @NgaySinh  VARCHAR(10)
  , @EnglishName VARCHAR(200)
  , @Nu        BIT
  , @TinhTrang INT
AS
BEGIN
    UPDATE dbo.tblHocSinh
    SET    Ho = ISNULL(@Ho, Ho)
         , Ten = ISNULL(@Ten, Ten)
         , NgaySinh = ISNULL(@NgaySinh, NgaySinh)
         , Nu = ISNULL(@Nu, Nu)
         , EnglishName = ISNULL(@EnglishName, '')
         , TinhTrang = ISNULL(@TinhTrang, TinhTrang)
         , TenTinhTrang = CASE
                               WHEN ISNULL(@TinhTrang, TinhTrang) = 0 THEN N'Đang học'
                               WHEN ISNULL(@TinhTrang, TinhTrang) = 1 THEN N'Nghỉ học'
                               ELSE N'Không xác định'
                          END
    WHERE HocSinhID = @HocSinhID;
END;