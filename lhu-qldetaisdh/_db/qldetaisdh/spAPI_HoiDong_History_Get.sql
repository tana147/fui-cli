CREATE PROC [dbo].[spAPI_HoiDong_History_Get]
@Student_ID VARCHAR(9),
@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @MsgError NVARCHAR(500);
	IF (@sys_SystemRight NOT IN (1, 2, 3, 9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này';
		RAISERROR(@MsgError, 16, 1);
		RETURN 0;
	END;

	-- Result set 1: Danh sách các hội đồng của học viên (kể cả đã xóa/hủy và đang hiệu lực)
	SELECT 
		H.HoiDongID,
		H.StudentID,
		H.DeTai,
		H.Decision_ID,
		D.Decision_SoQD,
		D.Decision_NgayQD,
		D.Decision_ThangQD,
		D.Decision_NamQD,
		H.ThoiGianBaoVe,
		H.DiemHoiDong,
		H.KetQuaHoiDong,
		H.HoiDong_Status,
		H.Is_PublishDiem,
		H.Is_Xoa,
		H.LyDoHuy,
		H.NhanXet,
		H.Created_By,
		H.Created_At,
		H.Updated_By,
		H.Updated_At
	FROM HoiDong H
	LEFT JOIN Decision D ON H.Decision_ID = D.Decision_ID
	WHERE H.StudentID = @Student_ID
	ORDER BY H.HoiDongID DESC;

	-- Result set 2: Thành viên của các hội đồng đó
	SELECT 
		TV.TVHDID,
		TV.HoiDongID,
		TV.StudentID,
		TV.GiangVienID,
		TV.HocViHocHam,
		TV.HoTenGiangVien,
		TV.CoQuanCongTac,
		TV.NganhGiangDay,
		TV.ChucTrach,
		TV.Diem,
		TV.Is_Xoa
	FROM HoiDongThanhVien TV
	WHERE TV.StudentID = @Student_ID
	ORDER BY TV.HoiDongID DESC, TV.TVHDID ASC;
END;
