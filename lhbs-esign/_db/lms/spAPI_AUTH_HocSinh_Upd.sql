CREATE PROC [dbo].[spAPI_AUTH_HocSinh_Upd]
    @HocSinhID INT
  , @Ho        NVARCHAR(200)
  , @Ten       NVARCHAR(200)
  , @NgaySinh  VARCHAR(10)
  , @EnglishName varchar(50)
  , @Nu        BIT
  , @TinhTrang INT
AS
BEGIN
   UPDATE dbo.tblHocSinh
    SET    Ho =			ISNULL(@Ho, Ho)
         , Ten =		ISNULL(@Ten, Ten)
         , NgaySinh =	ISNULL(@NgaySinh, NgaySinh)
         , Nu =				ISNULL(@Nu, Nu)
		 , EnglishName = ISNULL(@EnglishName, EnglishName)
         , TinhTrang = ISNULL(@TinhTrang, TinhTrang)
         , TenTinhTrang = CASE
                               WHEN  ISNULL(@TinhTrang, TinhTrang) = 0 THEN N'Đang học'
                               WHEN  ISNULL(@TinhTrang, TinhTrang) = 1 THEN N'Nghỉ học'
                               ELSE N'Không xác định'
                          END
    WHERE
           HocSinhID = @HocSinhID;
	IF @@ROWCOUNT =0
	BEGIN
		INSERT INTO tblHocSinh(HocSinhID, Ho, Ten, NgaySinh, Nu, EnglishName, TinhTrang)
		VALUES (@HocSinhID, @Ho, @Ten, @NgaySinh, @Nu, @EnglishName, @TinhTrang)
	END
END;