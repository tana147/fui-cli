
CREATE PROC [dbo].[spAPI_PhuHuynh_View_ByScreen]
@NienKhoa INT,
@HocSinhID INT, 
@TypeScreen INT,
@TypeID NVARCHAR(200),
@SYS_USERID VARCHAR(9)
AS
BEGIN
	DECLARE @LopID INT
	DECLARE @KhoiID INT
	SELECT TOP 1 @LopID = HSL.LopID
	FROM tblHocSinhLop HSL  INNER JOIN tblLop l on HSL.LopID = l.LopID
	                                                     AND HSL.NienKhoa = l.NienKhoa
	WHERE HSL.HocSinhID = @HocSinhID
	  AND HSL.NienKhoa = @NienKhoa
	  AND L.Enable = 1 AND L.NienKhoa = @NienKhoa
	
	UPDATE [dbo].[tblHocSinhYKienThang_ManHinh]
	SET 
		LuotXem = ISNULL(LuotXem, 0) + 1
	WHERE 
		LopID = @LopID AND 
		TypeScreen = @TypeScreen AND
		TypeID = @TypeID
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO [dbo].[tblHocSinhYKienThang_ManHinh](
			[HocSinhID], 
			[LopID], 
			[TypeScreen],
			[TypeID],
			[LuotXem], 
			[TrangThai], 
			[Enable], 
			[PHConfirm], 
			[PHConfirmTime]
		)
		VALUES(
			@HocSinhID, 
			@LopID, 
			@TypeScreen,
			@TypeID,  
			1, 
			0, 
			1, 
			@SYS_USERID, 
			GETDATE()
		)
	END
END 

