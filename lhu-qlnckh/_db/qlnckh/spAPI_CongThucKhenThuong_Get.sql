CREATE PROC [dbo].[spAPI_CongThucKhenThuong_Get]
AS
BEGIN
	SELECT [CongThucKhenThuongID], [CongThuckhenThuong], [DieuKhoanApDung], [QuyetDinhApDung], [NgayQuyetDinh], [CongThucHTML],[FieldRequired]
	FROM CongThucKhenThuong A WHERE A.Is_Xoa = 0
END