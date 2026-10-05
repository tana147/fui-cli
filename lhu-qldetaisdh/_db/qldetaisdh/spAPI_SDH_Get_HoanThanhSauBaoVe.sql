CREATE PROC [dbo].[spAPI_SDH_Get_HoanThanhSauBaoVe]
@NganhID INT,
@Sys_UserId VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @ChinhSua_TaskID_NC INT = 7
	DECLARE @ChinhSua_TaskID_UD INT = 25
	DECLARE @XetTotNghiep_TaskID_UD INT = 26
	DECLARE @XetTotNghiep_TaskID_NC INT = 9
	
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
	INNER JOIN Flow f1 ON f1.Student_ID = si.StudentID
		AND f1.Task_ID IN (@ChinhSua_TaskID_NC, @ChinhSua_TaskID_UD)
		AND f1.Flow_Status = 'C'
	INNER JOIN Flow f2 ON f2.Student_ID = si.StudentID
		AND f2.Task_ID IN (@XetTotNghiep_TaskID_NC, @XetTotNghiep_TaskID_UD)
		AND f2.Flow_Status = 'W'
	INNER JOIN HoiDong h ON h.StudentID = si.StudentID AND h.DiemHoiDong IS NOT NULL AND h.DiemHoiDong <> ''
	LEFT JOIN (
			SELECT 
				StudentID,
				MAX(CASE WHEN ChucTrach = N'Chủ tịch'
					THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ChuTich,
				-- COALESCE trả về giá trị đầu tiên không null
				COALESCE(
					MAX(CASE WHEN ChucTrach = N'Phản biện 1'
						THEN HocViHocHam + '. ' + HoTenGiangVien END),
					MAX(CASE WHEN ChucTrach = N'Phản biện'
						THEN HocViHocHam + '. ' + HoTenGiangVien END)
				) AS Pb_1,
				MAX(CASE WHEN ChucTrach = N'Phản biện 2'
					THEN HocViHocHam + '. ' + HoTenGiangVien END) AS Pb_2,
				MAX(CASE WHEN ChucTrach = N'Ủy viên'
					THEN HocViHocHam + '. ' + HoTenGiangVien END) AS UyVien,
				MAX(CASE WHEN ChucTrach = N'Thư ký'
					THEN HocViHocHam + '. ' + HoTenGiangVien END) AS ThuKy
			FROM HoiDongThanhVien
			WHERE Is_Xoa = 0
			GROUP BY StudentID
		) hd ON hd.StudentID = si.StudentID
	LEFT JOIN (SELECT c.Student_id
				, MAX(CASE WHEN fieldname='ThesisName' THEN text_content ELSE ' ' END) ThesisName
				, MAX(CASE WHEN fieldname='ThesisesProf1' THEN text_content ELSE N'' END) ThesisesProf1
				, MAX(CASE WHEN fieldname='ThesisesProf2' THEN text_content ELSE N'' END) ThesisesProf2
			FROM Flow_Detail a 
			INNER JOIN Task_Detail b ON a.Task_ID = b.Task_ID 
				AND a.Task_Detail_ID = b.Task_Detail_ID 
				AND b.FieldName IN('ThesisName'
									,'ThesisesProf1'
									,'ThesisesProf2') 
			 INNER JOIN Flow c on a.Flow_ID = c.Flow_ID  and c.use_yn = 1
				WHERE   a.use_yn = 1
				GROUP BY c.Student_ID
			) f3 ON f1.Student_ID = f3.Student_ID
	WHERE (@NganhID = 0 OR si.NganhID = @NganhID) 
	AND si.IsXuLyHocVu = 0
	ORDER BY si.StudentID
END