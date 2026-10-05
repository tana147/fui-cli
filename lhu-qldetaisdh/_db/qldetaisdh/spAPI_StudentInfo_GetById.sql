CREATE PROC [dbo].[spAPI_StudentInfo_GetById]
	@Student_ID VARCHAR(9)
AS
BEGIN
	SELECT 
		StudentID,
		MaHoSo,
		HoSV,
		TenSV,
		LopID,
		NganhID,
		TenNganh,
		HeDaoTao,
		NienKhoa,
		NgaySinh,
		Email,
		NoiSinh,
		GioiTinh,
		SoDienThoai,
		DanToc,
		QuocTich,
		CCCD,
		CONVERT(VARCHAR(10), NgayCap_CCCD, 105) AS NgayCap_CCCD,
		Truong_DaiHoc,
		Nganh_DaiHoc,
		ThoiGianTotNghiep_DaiHoc,
		Truong_ThacSi,
		Nganh_ThacSi,
		ThoiGianTotNghiep_ThacSi,
		XepLoai,
		NgoaiNgu_DauVao,
		Loai_NgoaiNgu_DauVao,
		BoSungKienThuc,
		CongBoKhoaHoc,
		IsXuLyHocVu,
		DiaChi,
		NoiLamViec,
		NgheNghiep,
		HeDaoTao_DaiHoc,
		HeDaoTao_ThacSi
	FROM StudentInfo
	WHERE StudentID = @Student_ID
END
