-- [dbo].[spAPI_BaoCaoLMS_Dashboard_By_CapID] 2
CREATE PROC [dbo].[spAPI_BaoCaoLMS_Dashboard_By_CapID]
@CapID INT
as
begin
	DECLARE @Bang_Tam TABLE
	(
		CapID INT,
		MonHocID INT,
		TenMonHoc_HienThi NVARCHAR(255),
		SoLuongBT_Tao INT,
		SoLuongBT_DaGiao_Lop INT,
		SoLuongBT_DaGiao_HocSinh INT
	);

	INSERT INTO @Bang_Tam
	SELECT 
		mh.CapID, 
		asm.MonHocID, 
		mh.TenMonHoc_HienThi, 

		COUNT(asm.AssignmentID) AS SoLuongBT_Tao,   -- Tổng số bài tập tạo theo môn
		(  
			SELECT COUNT(DISTINCT atc.AssignToClassID) AS BT
			FROM dbo.tblEL_AssignToClass atc
			INNER JOIN dbo.tblEL_Assignments asm2 
				ON asm2.AssignmentID = atc.AssignmentID 
				AND asm2.IsDeleted = 0 
				AND ISNULL(asm2.IsDev, 0) = 0
			WHERE 
				atc.IsDeleted = 0 
				AND atc.ResourceType = 'ASSIGNMENT'
				AND asm2.MonHocID = asm.MonHocID 
		) AS  SoLuongBT_DaGiao_Lop,
		(
			SELECT COUNT(DISTINCT ats.AssignmentID) AS BT
			FROM dbo.tblEL_AssignToStudent ats
			INNER JOIN dbo.tblEL_Assignments asm2 
				ON asm2.AssignmentID = ats.AssignmentID 
				AND asm2.IsDeleted = 0 
			WHERE 
				ats.IsDeleted = 0 
				AND asm2.MonHocID = asm.MonHocID
				AND ats.ResourceType = 'ASSIGNMENT'
				AND ISNULL(asm2.IsDev, 0) = 0
		) AS SoLuongBT_DaGiao_HocSinh
	FROM dbo.tblEL_Assignments asm
	INNER JOIN dbo.tblMonHoc mh 
		ON mh.MonHocID = asm.MonHocID 
	   AND mh.Enable = 1
	   AND mh.CapID = @CapID
	WHERE asm.IsDeleted = 0 AND ISNULL(asm.IsDev, 0) = 0
	GROUP BY mh.CapID, asm.MonHocID, mh.TenMonHoc_HienThi
	ORDER BY mh.CapID, mh.TenMonHoc_HienThi;

	SELECT (	
		SELECT TOP 1 TenMonHoc_HienThi
		FROM @Bang_Tam
		ORDER BY SoLuongBT_Tao DESC 
	) as MonHoc_TaoBT_NhieuNhat,
	(
		SELECT Sum(SoLuongBT_Tao)
		FROM @Bang_Tam
	) as TongBaiTap_Tao_TheoCap,
	(
		SELECT 
			TOP 1
			asm.CreateUser as GiaoVienID,
			COUNT(asm.AssignmentID) AS SoLuongBaiTap
		FROM @Bang_Tam AS t
		INNER JOIN dbo.tblEL_Assignments AS asm 
			ON asm.MonHocID = t.MonHocID 
			AND asm.IsDeleted = 0
		AND ISNULL(asm.IsDev, 0) = 0
		GROUP BY asm.CreateUser
		order by SoLuongBaiTap desc
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	) as GiaoVien_TaoBT_NhieuNhat
 
	SELECT * 
	FROM @Bang_Tam;

	SELECT 
		   gv.GiaoVienID,
		   gv.HoGV + ' ' + gv.TenGV AS HoTen,
		   COUNT(asm.AssignmentID) AS SoLuong
	FROM dbo.tblEL_Assignments asm
		INNER JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = asm.CreateUser

	WHERE asm.IsDeleted = 0
	AND asm.KhoiID IN (SELECT KhoiID FROM dbo.tblKhoi WHERE CapID = @CapID)
	AND ISNULL(asm.IsDev, 0) = 0
	GROUP BY gv.GiaoVienID, gv.HoGV + ' ' + gv.TenGV
	ORDER BY COUNT(asm.AssignmentID) DESC;
end
