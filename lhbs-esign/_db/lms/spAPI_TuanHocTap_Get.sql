-- spAPI_TuanHocTap_Get 2025
CREATE PROC [dbo].[spAPI_TuanHocTap_Get]
	@NienKhoa INT
as
BEGIN
	SELECT 
		TuanHocID,
		ThangHoc,
		Tuan,
		NgayBatDau,
		NgayKetThuc,
		TuanTrongNam,
		N'Tuần ' + CAST(Tuan AS VARCHAR(2))
			+ N' - Tháng ' + CAST(ThangHoc as varchar(2))
			+ N' - (' + FORMAT(NgayBatDau ,'dd/MM/yyyy') 
			+ N' - ' + FORMAT(NgayKetThuc,'dd/MM/yyyy') + ')'  AS Tuan_HienThi,
		CASE 
    WHEN CAST(GETDATE() AS DATE) BETWEEN NgayBatDau AND NgayKetThuc
    THEN 1 
    ELSE 0 
END AS Is_Active
	FROM dbo.tblTuanHocTap
	WHERE NienKhoa = @NienKhoa;
END 