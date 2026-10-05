
CREATE PROC [dbo].[spAPI_HoiDong_GiangVien_Upd_Diem]
@HoiDongID INT
,@StudentID VARCHAR(9)
,@DiemHoiDongObj NVARCHAR(MAX)
,@HoiDongThanhVienObj_Arr NVARCHAR(MAX)
,@SYS_UserID VARCHAR(9)
,@sys_SystemRight INT
AS
BEGIN
	DECLARE @MsgError NVARCHAR(500)
	IF (@sys_SystemRight NOT IN (1,2,3,9))
	BEGIN 
		SET @MsgError = N'Bạn không có quyền thực hiện tác vụ này '
		RAISERROR(@MsgError, 16, 1)
		RETURN 0;
	END

	----update vào table HoiDong
	UPDATE [dbo].[HoiDong]
	SET 
		[DiemHoiDong]			=	json.DiemHoiDong
		,[NhanXet]				=	json.NhanXet
		,[FileNhanXetID]		=	json.FileNhanXetID
		,[FileNhanXetName]		=	json.FileNhanXetName
		,[FileKiemPhieuID]		=	json.FileKiemPhieuID
		,[FileKiemPhieuName]	=	json.FileKiemPhieuName
		,[Updated_By]			=	@SYS_UserID
		,[Updated_At]			=	GETDATE()
	FROM OPENJSON(@DiemHoiDongObj)
	WITH (
		DiemHoiDong FLOAT,
		NhanXet NVARCHAR(500),
		FileNhanXetID varchar(32),
		FileNhanXetName NVARCHAR(200),
		FileKiemPhieuID varchar(32),
		FileKiemPhieuName NVARCHAR(200)
	) AS json
	WHERE [dbo].[HoiDong].HoiDongID = @HoiDongID

	----update vào table HoiDongThanhVien
	UPDATE [dbo].[HoiDongThanhVien]
	SET 
		[Diem]				=	json.Diem
		,[NhanXet]			=	json.NhanXet
		,[FileNhanXetID]	=	json.FileNhanXetID
		,[FileNhanXetName]	=	json.FileNhanXetName
		,[FileDiemID]		=	json.FileDiemID
		,[FileDiemName]		=	json.FileDiemName
		,[Updated_By]		=	@SYS_UserID
		,[Updated_At]		=	GETDATE()
	FROM OPENJSON(@HoiDongThanhVienObj_Arr)
	WITH (
		TVHDID INT,
		Diem FLOAT,
		NhanXet NVARCHAR(500),
		FileNhanXetID varchar(32),
		FileNhanXetName NVARCHAR(200),
		FileDiemID varchar(32),
		FileDiemName NVARCHAR(200)
	) AS json
	WHERE [dbo].[HoiDongThanhVien].TVHDID= json.TVHDID
END