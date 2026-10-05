CREATE PROC [dbo].[spAPI_HoiDong_GiangVien_Get]
@NganhID INT
AS
BEGIN
	DECLARE @TargetTenNganh NVARCHAR(200) = ''
	SELECT @TargetTenNganh = TenNganh FROM Nganh WHERE NganhID = @NganhID

	SELECT ROW_NUMBER() OVER (ORDER BY GiangVienID) AS 'STT'
	, 0 AS Is_Chon
	, GiangVienID
	, [HocViHocHam]
	, [HoTenGiangVien]
	, [CoQuanCongTac]
	, [NganhGiangDay] 
	, [NganhID]
	FROM [dbo].[GiangVien] 
	WHERE (
		@NganhID = 0 
		OR NganhID = @NganhID
		OR (@NganhID = 44 AND NganhID = 37) -- Khoa học máy tính (TS) <-> CNTT
		OR (@NganhID = 43 AND NganhID = 38) -- Quản trị kinh doanh (TS) <-> QTKD
		OR (@NganhID = 58 AND NganhID = 42) -- Kỹ thuật xây dựng (TS) <-> KTXD
		OR (@TargetTenNganh <> '' AND (NganhGiangDay LIKE '%' + @TargetTenNganh + '%' OR NganhID IN (SELECT NganhID FROM Nganh WHERE TenNganh = @TargetTenNganh)))
	)
	AND IS_XOA = 0
END
