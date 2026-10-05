CREATE PROCEDURE [dbo].[spAPI_RPT_AnPham_NamDang_Dashboard_Update]
	@AnPhamID INT,
	@TenLoaiAnPham_Edit NVARCHAR(100),
	@DiemHeSoChatLuong_Edit NUMERIC(18,2),
	@GroupAnPham_Edit INT,
	@HeSoChatLuongID_Edit INT,
	@sys_UserID VARCHAR(9)
	AS
BEGIN
	IF(@DiemHeSoChatLuong_Edit = -1)
	BEGIN
		SET @DiemHeSoChatLuong_Edit = null
	END
		UPDATE dbo.AnPham
			SET TenLoaiAnPham_Edit = @TenLoaiAnPham_Edit,
				HeSoChatLuongID_Edit = @HeSoChatLuongID_Edit,
				DiemHeSoChatLuong_Edit = @DiemHeSoChatLuong_Edit,
				GroupAnPham_Edit= @GroupAnPham_Edit,
				UpdateUser_Edit = @sys_UserID,
				UpdateTime_Edit = GETDATE()
		WHERE AnPhamID = @AnPhamID
END