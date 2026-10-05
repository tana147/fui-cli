
CREATE PROC [dbo].[spAPI_HoiDong_Old_Ins]
@HoiDongID INT,
@StudentID VARCHAR(9),

@SYS_UserID VARCHAR(9),
@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	DECLARE @Process_Student_ID INT
	DECLARE @Flow_ID_DK_BaoVe INT
	DECLARE @Flow_ID_Bao_Ve INT

	-- Lấy Process student ID của HV
	SELECT @Process_Student_ID = Process_Stu_ID
	FROM Process_Student
	WHERE Student_ID = @StudentID AND Process_ID IN (1,4) AND Process_Student_Status <> 'X'

	--Insert vào hội đồng cũ
	INSERT INTO HoiDong_Old
	(
			HoiDongID
		  ,StudentID
		  ,DeTai
		  ,Decistion_ID
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
		  ,Is_Xoa
		  ,Created_By
		  ,Created_At
	)
	SELECT 
			HoiDongID
		  ,StudentID
		  ,DeTai
		  ,Decision_ID
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
		  ,Is_Xoa
		  ,@SYS_UserID
		  ,GETDATE()
	  FROM HoiDong
	  WHERE HoiDongID = @HoiDongID
		
	--Insert vào hội đồng thành viên cũ
	INSERT INTO HoiDongThanhVien_Old
	(
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
		  ,Is_Xoa
		  ,Created_By
		  ,Created_At
	)
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
		  ,Is_Xoa
		  ,@SYS_UserID
		  ,GETDATE()
	FROM HoiDongThanhVien
	WHERE HoiDongID = @HoiDongID

	-- Insert Đăng ký bảo vệ cũ
	SELECT @Flow_ID_DK_BaoVe = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'signForDefendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	INSERT INTO Flow_Detail_Old
	(
			Flow_Detail_ID
		  ,Flow_ID
		  ,Task_ID
		  ,Task_Detail_ID
		  ,History_Type
		  ,File_URL
		  ,Text_Content
		  ,File_Name
		  ,File_ID
		  ,File_Type
		  ,Flow_Detail_Status
		  ,use_yn
		  ,Created_By
		  ,Created_At
	)
	SELECT 
		Flow_Detail_ID
		  ,Flow_ID
		  ,Task_ID
		  ,Task_Detail_ID
		  ,'SignDefendThesis'
		  ,File_URL
		  ,Text_Content
		  ,File_Name
		  ,File_ID
		  ,File_Type
		  ,Flow_Detail_Status
		  ,use_yn
		  ,'Nam'
		  ,GETDATE()
	FROM Flow_Detail
	WHERE Flow_ID = @Flow_ID_DK_BaoVe

	-- Insert Bảo vệ đề tài cũ
	SELECT @Flow_ID_Bao_Ve = f.Flow_ID
	FROM Flow f
	INNER JOIN Tasks t ON f.Task_ID = t.Task_ID AND Task_Description = 'defendThesis'
	WHERE Process_Student_ID = @Process_Student_ID

	INSERT INTO Flow_Detail_Old
	(
			Flow_Detail_ID
		  ,Flow_ID
		  ,Task_ID
		  ,Task_Detail_ID
		  ,History_Type
		  ,File_URL
		  ,Text_Content
		  ,File_Name
		  ,File_ID
		  ,File_Type
		  ,Flow_Detail_Status
		  ,use_yn
		  ,Created_By
		  ,Created_At
	)
	SELECT 
		Flow_Detail_ID
		  ,Flow_ID
		  ,Task_ID
		  ,Task_Detail_ID
		  ,'DefendThesis'
		  ,File_URL
		  ,Text_Content
		  ,File_Name
		  ,File_ID
		  ,File_Type
		  ,Flow_Detail_Status
		  ,use_yn
		  ,'Nam'
		  ,GETDATE()
	FROM Flow_Detail
	WHERE Flow_ID = @Flow_ID_Bao_Ve

	-- Set trạng thái bảo vệ thành thất bại
	UPDATE HoiDong
	SET KetQuaHoiDong = 2
	WHERE HoiDongID = @HoiDongID
END
