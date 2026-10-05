CREATE PROC [dbo].[spAPI_AnPham_Loai_Sub_Get]
@LoaiAnPhamID INT
AS
BEGIN
	SELECT  LoaiSubAnPhamID, [TenLoaiSubAnPham], [Sort], [MoTa] FROM AnPham_Loai_Sub
	WHERE LoaiAnPhamID = @LoaiAnPhamID AND [Is_Xoa] = 0
	ORDER BY SORT
END