
CREATE PROC [dbo].[spAPI_HoiDong_Old_Get]
@StudentID VARCHAR(9),

@SYS_UserID VARCHAR(9),
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

	DECLARE @HoiDongID INT
	DECLARE @Process_Student_ID INT
	DECLARE @Flow_ID_DK_BaoVe INT
	DECLARE @Flow_ID_Bao_Ve INT

	-- Lấy HoiDongID của HV
	SELECT TOP 1 @HoiDongID = HoiDongID
	FROM HoiDong_Old
	WHERE StudentID = @StudentID

	-- Lấy Process student ID của HV
	SELECT @Process_Student_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1,4) AND Process_Student_Status <> 'X'

	-- Đăng ký bảo vệ luận văn/đồ án
	SELECT @Flow_ID_DK_BaoVe = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'signForDefendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Bảo vệ luận văn/đồ án
	SELECT @Flow_ID_Bao_Ve = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'defendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	-- Thông tin hội đồng
	SELECT 
		HoiDongID
		,StudentID
		,DeTai
		,Decistion_ID
		,d.Decision_SoQD
		,LoaiHoiDong
		,DiemHoiDong
		,KetQuaHoiDong
		,NhanXet
		,FileNhanXetID
		,FileNhanXetName
		,ThoiGianBaoVe
		,FileKiemPhieuID
		,FileKiemPhieuName
		,HoiDong_Status
		,Is_PublishDiem
	FROM HoiDong_Old hd
	LEFT JOIN Decision d ON d.Decision_ID = hd.Decistion_ID
	WHERE HoiDongID = @HoiDongID

	-- Thông tin thành viên hội đồng
	SELECT 
		TVHDID
		,HoiDongID
		,StudentID
		,GiangVienID
		,HocViHocHam
		,HoTenGiangVien
		,CoQuanCongTac
		,NganhGiangDay
		,ChucTrach
		,Diem
		,KetQua
		,NhanXet
		,FileNhanXetID
		,FileNhanXetName
		,FileDiemID
		,FileDiemName
		,Is_PublishDiem
	FROM HoiDongThanhVien_Old
	WHERE HoiDongID = @HoiDongID

	-- Dữ liệu đăng ký bảo vệ đề tài cũ
	SELECT 
		Flow_Detail_Old_ID
      ,Flow_Detail_ID
      ,Flow_ID
      ,fd.Task_ID
      ,fd.Task_Detail_ID
      ,History_Type
	  ,td.Task_Detail_Description
	  ,td.Task_Detail_Seq
	  ,td.Task_Detail_Display
	  ,td.Task_Detail_Type
      ,File_URL
      ,Text_Content
      ,File_Name
      ,File_ID
      ,File_Type
      ,Flow_Detail_Status
	FROM Flow_Detail_Old fd
	INNER JOIN Task_Detail td ON td.Task_Detail_ID = fd.Task_Detail_ID
	WHERE History_Type = 'SignDefendThesis' AND Flow_ID = @Flow_ID_DK_BaoVe
	ORDER BY td.Task_Detail_Seq ASC

	-- Dữ liệu bảo vệ đề tài cũ
	SELECT 
		Flow_Detail_Old_ID
      ,Flow_Detail_ID
      ,Flow_ID
      ,fd.Task_ID
      ,fd.Task_Detail_ID
      ,History_Type
	  ,td.Task_Detail_Description
	  ,td.Task_Detail_Seq
	  ,td.Task_Detail_Display
	  ,td.Task_Detail_Type
      ,File_URL
      ,Text_Content
      ,File_Name
      ,File_ID
      ,File_Type
      ,Flow_Detail_Status
	FROM Flow_Detail_Old fd
	INNER JOIN Task_Detail td ON td.Task_Detail_ID = fd.Task_Detail_ID
	WHERE History_Type = 'DefendThesis' AND Flow_ID = @Flow_ID_Bao_Ve
	ORDER BY td.Task_Detail_Seq ASC

END
