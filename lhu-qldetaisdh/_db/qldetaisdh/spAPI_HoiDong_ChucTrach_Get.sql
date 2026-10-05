CREATE PROC [dbo].[spAPI_HoiDong_ChucTrach_Get] 
@NganhID INT,
@LopID VARCHAR(9)
AS
BEGIN
	IF @NganhID = 102 OR @LopID IN ('23CP911', '23CP912', '23CP913')
	BEGIN
		SELECT  [ChucTrach] FROM [ChucTrach] WHERE ChucTrachID IN (1,6,5) ORDER BY Sort
	END
	ELSE 
	BEGIN
		SELECT  [ChucTrach] FROM [ChucTrach] WHERE ChucTrachID <> 6
	END
	
END