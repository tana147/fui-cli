CREATE PROC [dbo].[spAPI_SDH_Get_HoanThanhSauBaoVe_TS]
@NganhID INT,
@Sys_UserId VARCHAR(9),
@sys_SystemRight INT,
@sys_FunctionRight VARCHAR(2000)
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (ISNULL(@sys_SystemRight, 0) NOT IN (1,2,3,9) AND CHARINDEX('[2]', ISNULL(@sys_FunctionRight, '')) = 0)
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này'
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	SELECT DISTINCT
		si.StudentID,
		si.HoSV,
		si.TenSV,
		si.GioiTinh,
		si.NgaySinh,
		si.TenNganh,
		si.NganhID,
		si.NienKhoa AS Nien_Khoa,
		si.LopID,
		h.DiemHoiDong,
		si.SoDienThoai,
		si.Email,
		f3.ThesisName,
		f3.ThesisesProf1,
		f3.ThesisesProf2,
		hd.ChuTich,
		hd.Pb_1,
		hd.Pb_2,
		hd.UyVien,
		hd.ThuKy
	FROM StudentInfo si
	INNER JOIN Flow f ON f.Student_ID = si.StudentID AND f.Task_ID = 46 AND f.use_yn = 1
	LEFT JOIN HoiDong h ON h.StudentID = si.StudentID AND h.DiemHoiDong IS NOT NULL AND h.DiemHoiDong <> ''
	LEFT JOIN (
		SELECT 
			StudentID,
			MAX(CASE WHEN ChucTrach = N'Chủ tịch' THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ChuTich,
			COALESCE(
				MAX(CASE WHEN ChucTrach = N'Phản biện 1' THEN HocViHocHam + '. ' + HoTenGiangVien END),
				MAX(CASE WHEN ChucTrach = N'Phản biện' THEN HocViHocHam + '. ' + HoTenGiangVien END)
			) AS Pb_1,
			MAX(CASE WHEN ChucTrach = N'Phản biện 2' THEN HocViHocHam + '. ' + HoTenGiangVien END) AS Pb_2,
			MAX(CASE WHEN ChucTrach = N'Ủy viên' THEN HocViHocHam + '. ' + HoTenGiangVien END) AS UyVien,
			MAX(CASE WHEN ChucTrach = N'Thư ký' THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ThuKy
		FROM HoiDongThanhVien
		WHERE Is_Xoa = 0
		GROUP BY StudentID
	) hd ON hd.StudentID = si.StudentID
	LEFT JOIN (
		SELECT c.Student_id,
			MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE '' END) ThesisName,
			MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE '' END) ThesisesProf1,
			MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE '' END) ThesisesProf2
		FROM Flow_Detail a 
		INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID AND a.Task_Detail_ID = b.Task_Detail_ID 
			AND b.FieldName IN ('ThesisName', 'ThesisesProf1', 'ThesisesProf2')
		INNER JOIN Flow c ON a.Flow_ID = c.Flow_ID AND c.use_yn = 1
		WHERE a.use_yn = 1
		GROUP BY c.Student_ID
	) f3 ON f3.Student_ID = si.StudentID
	WHERE (@NganhID = 0 OR si.NganhID = @NganhID)
	  AND (si.HeDaoTao = 'Phd' OR SUBSTRING(si.LopID, 3, 1) = 'N' OR si.NganhID IN ('43', '44'))
	  AND (si.IsXuLyHocVu = 0 OR si.IsXuLyHocVu IS NULL)
	ORDER BY si.StudentID
END