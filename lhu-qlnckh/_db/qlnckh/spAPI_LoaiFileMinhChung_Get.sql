CREATE PROC spAPI_LoaiFileMinhChung_Get
AS
BEGIN
	SELECT 2 AS LoaiFile , N'File minh chứng Chi phí đăng bài' AS TenChiPhi
	UNION
	SELECT 3 AS LoaiFile , N'File minh chứng phí thông báo' AS TenChiPhi
	UNION
	SELECT 4 AS LoaiFile , N'Loại Khác' AS TenChiPhi
END