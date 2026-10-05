-- [dbo].[spAPI_Student_Get_NienKhoa_TS] '0'
CREATE PROC [dbo].[spAPI_Student_Get_NienKhoa_TS]
@NienKhoa VARCHAR(10)
AS
BEGIN
	-- WITH: Tạo bảng tạm lọc danh sách nghiên cứu sinh Tiến sĩ
	WITH RankedData as (
		SELECT 
			S.StudentID, 
			S.MaHoSo,
			S.HoSV, 
			S.TenSV, 
			S.LopID, 
			S.KhoaID, 
			S.NganhID, 
			S.TenNganh, 
			S.HeDaoTaoID, 
			S.HeDaoTao, 
			S.NienKhoa,  
			S.NgaySinh,
			S.NoiSinh, 
			S.GioiTinh, 
			S.SoDienThoai, 
			S.Email,
			S.DanToc,
			S.QuocTich,
			S.CCCD,
			CONVERT(VARCHAR(10), S.NgayCap_CCCD, 105) AS NgayCap_CCCD,
			S.Truong_DaiHoc,
			S.Nganh_DaiHoc,
			S.ThoiGianTotNghiep_DaiHoc,
			S.Truong_ThacSi,
			S.Nganh_ThacSi,
			S.ThoiGianTotNghiep_ThacSi,
			S.XepLoai,
			S.NgoaiNgu_DauVao,
			S.Loai_NgoaiNgu_DauVao,
			S.BoSungKienThuc,
			S.CongBoKhoaHoc,
			S.IsXuLyHocVu,
			S.DiaChi,
			S.NoiLamViec,
			S.NgheNghiep,
			S.HeDaoTao_DaiHoc,
			S.HeDaoTao_ThacSi,
			F.Seq,
			F.Flow_Status,
			ROW_NUMBER() OVER (PARTITION BY s.[StudentID] ORDER BY F.[Seq] ASC) AS rn
		FROM StudentInfo S
		LEFT JOIN Flow F ON F.Student_ID = S.StudentID 
		WHERE (F.Flow_Status IS NULL OR NOT F.Flow_Status = 'x')
		AND (@NienKhoa = '0' OR S.NienKhoa = @NienKhoa)
		AND (S.HeDaoTao = 'Phd' OR SUBSTRING(S.LopID, 3, 1) = 'N' OR S.NganhID IN ('43', '44'))
	)
	-- Lấy dữ liệu từ RankedData kết hợp với số dòng của Process_Student
	SELECT 
		R.*, 
		ps.Process_ID,
		COALESCE(P.TotalRows, 0) AS TotalChangeThesis,
		CASE 
        WHEN EXISTS (
            SELECT 1
            FROM Flow_His FD
            WHERE FD.Student_ID = R.StudentID
        ) THEN 1 
        ELSE 0
    END AS HasResetProcess
	FROM RankedData R
	OUTER APPLY (
		SELECT COUNT(*) AS TotalRows
		FROM Process_Student P
		WHERE P.Student_ID = R.StudentID
	) P
	LEFT JOIN Process_Student ps ON ps.Student_ID = R.StudentID 
		AND ps.Process_ID IN (4, 6)
		AND ps.Process_Student_Status <> 'X'
	WHERE rn = 1
	ORDER BY R.StudentID
END
