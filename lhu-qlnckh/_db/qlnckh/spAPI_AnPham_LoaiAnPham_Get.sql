CREATE PROC [dbo].[spAPI_AnPham_LoaiAnPham_Get]
AS
BEGIN
	SELECT LoaiAnPhamID, TenLoaiAnPham FROM AnPham_Loai where Is_Xoa = 0 ORDER BY SORT
END