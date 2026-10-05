CREATE PROC spAPI_ToTrinh_Get
AS
BEGIN
	SELECT [ToTrinhID], [Ngay], [Thang], [Nam], [SoQD], [TieuDeQuyetDinh], [NamHocKhenThuong], [DotKhenThuong], [ToTrinhFileID], [ToTrinhFileUrl], [ToTrinhFileName], [ToTrinhLoai]
	FROM ToTrinh WHERE Is_Xoa = 0
END