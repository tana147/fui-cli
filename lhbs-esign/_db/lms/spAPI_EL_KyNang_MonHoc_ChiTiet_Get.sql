-- [dbo].[spAPI_EL_KyNang_MonHoc_ChiTiet_Get] 1
CREATE PROC [dbo].[spAPI_EL_KyNang_MonHoc_ChiTiet_Get] @KyNang_MonHocID INT
AS
BEGIN
    SELECT 
		  ct.KyNang_MonHoc_ChiTietID	
		, ct.KyNang_MonHocID	
		, ct.TenKyNang	
		, ct.MoTaKyNang
		, mh.NhomKyNang
    FROM
           tblEL_KyNang_MonHoc_ChiTiet ct
		INNER JOIN dbo.tblEL_KyNang_MonHoc mh ON mh.KyNang_MonHocID = ct.KyNang_MonHocID AND mh.IsDeleted = 0
    WHERE
           ct.KyNang_MonHocID = @KyNang_MonHocID
      AND  ct.IsDeleted        = 0;
END;