-- spAPI_TuanHocTap_Get_Thang_Nam
CREATE PROC spAPI_TuanHocTap_Get_Thang_Nam
	@NienKhoa INT
AS
BEGIN
    SELECT 
		DISTINCT Nam, ThangHoc AS Thang, NienKhoa ,
	N'Tháng ' + CAST(ThangHoc AS VARCHAR(2)) + '/' + CAST(Nam AS VARCHAR(4))	as Thang_Nam_HienThi
	FROM dbo.tblTuanHocTap
	WHERE NienKhoa = @NienKhoa
END





