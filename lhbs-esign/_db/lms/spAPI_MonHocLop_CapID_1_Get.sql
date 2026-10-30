CREATE proc [dbo].[spAPI_MonHocLop_CapID_1_Get]
AS
begin
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
	SELECT 
		LopID,
		TenLop,
		CapID
	FROM dbo.tblLop
	WHERE CapID = 1 AND NienKhoa = @NienKhoa
	ORDER BY TenLop
end