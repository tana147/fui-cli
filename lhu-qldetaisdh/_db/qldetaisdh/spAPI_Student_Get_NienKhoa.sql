-- [dbo].[spAPI_Student_Get_NienKhoa] '2022-01'
CREATE PROC [dbo].[spAPI_Student_Get_NienKhoa]
@NienKhoa VARCHAR(10)
AS
BEGIN
	-- WITH: Tạo bảng tạm
	WITH RankedData as (
		SELECT 
			S.StudentID, 
			S.HoSV, 
			S.TenSV,
			S.LopID, 
			S.KhoaID, 
			S.NganhID, 
			S.TenNganh, 
			S.HeDaoTaoID, 
			S.HeDaoTao, 
			S.NienKhoa,  
			-- CONVERT(date, S.NgaySinh , 103) as NgaySinh,
			S.NgaySinh,
			S.NoiSinh, 
			S.GioiTinh, 
			S.SoDienThoai, 
			S.Email,
			S.DanToc,
			S.QuocTich,
			S.CCCD,
			S.NgayCap_CCCD,
			S.Truong_DaiHoc,
			S.Nganh_DaiHoc,
			S.ThoiGianTotNghiep_DaiHoc,
			S.XepLoai,
			S.NgoaiNgu_DauVao,
			S.Loai_NgoaiNgu_DauVao,
			S.BoSungKienThuc,
			S.CongBoKhoaHoc,
			S.IsXuLyHocVu,
			F.Seq,
			F.Flow_Status,
			-- Thêm dòng đánh số thứ tự để chỉ lấy dòng có giá trị thấp nhất của Seq
			ROW_NUMBER() OVER (PARTITION BY s.[StudentID] ORDER BY F.[Seq] ASC) AS rn
		FROM StudentInfo S
		LEFT JOIN Flow F ON F.Student_ID = S.StudentID 
		WHERE NOT F.Flow_Status = 'x' 
		AND (@NienKhoa = '0' OR S.NienKhoa = @NienKhoa)
	)
	-- Lấy dữ liệu từ RankedData kết hợp với số dòng của Process_Student
	SELECT 
		R.*, 
		ps.Process_ID,
		COALESCE(P.TotalRows, 0) AS TotalChangeThesis, -- Nếu không có dữ liệu trong Process_Student, trả về 0 thay vì NULL
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
		-- Đếm số lượng dòng trong Process_Student ứng với StudentID
		SELECT COUNT(*) AS TotalRows
		FROM Process_Student P
		WHERE P.Student_ID = R.StudentID
	) P
	-- Lấy Process_ID
	LEFT JOIN Process_Student ps ON ps.Student_ID = R.StudentID 
		AND ps.Process_ID IN (1, 4)
		AND ps.Process_Student_Status <> 'X'
	WHERE rn = 1 -- Chỉ lấy dòng có Seq nhỏ nhất (không trùng StudentID)
	ORDER BY R.StudentID
END

