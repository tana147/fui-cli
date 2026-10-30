-- [dbo].[spAPI_BaoCao_TongHop_Get]1
CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Get]
	@CapID INT
AS
BEGIN
    SELECT bc.*, mh.TenMonHoc_HienThi 
	FROM tblBaoCao bc
		LEFT JOIN dbo.tblMonHoc mh ON bc.MonHocID = mh.MonHocID AND mh.Enable = 1
	WHERE bc.Enable = 1 AND bc.CapID = @CapID
END

