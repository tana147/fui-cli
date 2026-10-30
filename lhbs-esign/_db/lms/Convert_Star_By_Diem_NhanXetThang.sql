CREATE FUNCTION [dbo].[Convert_Star_By_Diem_NhanXetThang]
(
    @Diem float
)
RETURNS NVARCHAR(100)
AS
BEGIN
	--Tối thiểu là 2 sao
	DECLARE @Star int = 2
     IF (@Diem BETWEEN 9 AND 10)
	 BEGIN
	     SET @Star = 5
	 END
	 ELSE IF (@Diem BETWEEN 7 AND 8)
	 BEGIN
	     SET @Star = 4
	 END
	 ELSE IF (@Diem BETWEEN 5 AND 6)
	 BEGIN
	     SET @Star = 3
	 END
	 ELSE
		SET @Star = 2
	 
	 RETURN @Star
END;
