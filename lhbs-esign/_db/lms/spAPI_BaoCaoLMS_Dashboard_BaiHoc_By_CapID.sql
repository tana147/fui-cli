-- [dbo].[spAPI_BaoCaoLMS_Dashboard_By_CapID] 2
CREATE PROC [dbo].[spAPI_BaoCaoLMS_Dashboard_BaiHoc_By_CapID]
	@CapID INT
, @NienKhoa INT
as
begin
	DECLARE @Bang_Tam TABLE
	(
		CapID INT,
		Sort INT,
		MonHocID INT,
		TenMonHoc_HienThi NVARCHAR(255),
		SoLuongBH_Tao INT,
		SoLuongBH_DaGiao INT
	);

	INSERT INTO @Bang_Tam
	SELECT 
		mh.CapID,
		mh.Sort,
		ls.MonHocID,
		mh.TenMonHoc_HienThi,
		COUNT(ls.LessonID) AS SoLuongBH_Tao,
		(  
				SELECT COUNT(DISTINCT atc.AssignToClassID) AS BT
				FROM dbo.tblEL_AssignToClass atc
				INNER JOIN dbo.tblEL_Lessons ls2
					ON ls2.LessonID = atc.ResourceID
					AND ls2.IsDeleted = 0 
				WHERE 
					atc.IsDeleted = 0 
					AND atc.ResourceType = 'LESSON'
					AND ls2.MonHocID = ls.MonHocID 
		) AS SoLuongBH_DaGiao
	FROM dbo.tblEL_Lessons ls 
		INNER JOIN dbo.tblMonHoc mh ON mh.MonHocID = ls.MonHocID AND mh.Enable = 1 AND mh.CapID = @CapID
	WHERE  ls.IsDeleted = 0 AND ls.NienKhoa = @NienKhoa
	GROUP BY ls.MonHocID,mh.CapID, mh.TenMonHoc_HienThi, mh.Sort
	ORDER BY ls.MonHocID


	SELECT (	
		SELECT TOP 1 TenMonHoc_HienThi
		FROM @Bang_Tam
		ORDER BY SoLuongBH_Tao DESC 
	) as MonHoc_TaoBH_NhieuNhat,
	(
		SELECT Sum(SoLuongBH_Tao)
		FROM @Bang_Tam
	) as TongBaiHoc_Tao_TheoCap,
	(
		SELECT 
			TOP 1
			ls.CreateUser as GiaoVienID,
			COUNT(ls.LessonID) AS SoLuongBaiHoc
		FROM @Bang_Tam AS t
		INNER JOIN dbo.tblEL_Lessons AS ls
			ON ls.MonHocID = t.MonHocID 
			AND ls.IsDeleted = 0
			AND ls.CreateUser <> 'NA0000022'
		GROUP BY ls.CreateUser
		order by SoLuongBaiHoc desc
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	) as GiaoVien_TaoBH_NhieuNhat
 
	SELECT * 
	FROM @Bang_Tam;

	SELECT 
		   gv.GiaoVienID,
		   gv.HoGV + ' ' + gv.TenGV AS HoTen,
		   COUNT(ls.LessonID) AS SoLuong
	FROM dbo.tblEL_Lessons ls
		INNER JOIN dbo.tblGiaoVien gv ON gv.GiaoVienID = ls.CreateUser

	WHERE ls.IsDeleted = 0
	AND ls.KhoiID IN (SELECT KhoiID FROM dbo.tblKhoi WHERE CapID = @CapID)
	AND ls.CreateUser <> 'NA0000022'
	GROUP BY gv.GiaoVienID, gv.HoGV + ' ' + gv.TenGV
	ORDER BY COUNT(ls.LessonID) DESC;
end
