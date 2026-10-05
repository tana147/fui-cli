
-- [dbo].[spAPI_RPT_BBKH_Summary_ByLoaiAnPhamID] 4, 'GV0000611',9 
CREATE PROC [dbo].[spAPI_RPT_BBKH_Summary_ByLoaiAnPhamID]
@LoaiAnPhamID INT,
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN

	SELECT C.TenLoaiSubAnPham AS [Col_Name], COUNT(*) SL_BB FROM AnPham A 
	INNER JOIN BaiBaoKhoaHoc B ON A.AnPhamID = B.AnPhamID 
	INNER JOIN AnPham_Loai_Sub C ON A.LoaiSubAnPhamID = C.LoaiSubAnPhamID
	WHERE A.Is_Xoa = 0 AND B.Is_Xoa = 0 AND C.LoaiAnPhamID = @LoaiAnPhamID AND C.Is_Xoa = 0
	GROUP BY C.TenLoaiSubAnPham

END
