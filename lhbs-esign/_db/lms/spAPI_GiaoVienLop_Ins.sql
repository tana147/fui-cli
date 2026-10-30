CREATE PROC [dbo].[spAPI_GiaoVienLop_Ins] -- -1, 0, 'NV0000263', 2, 0,'NA0000022'
@NienKhoa INT = 2024,
@KhoiID INT,
@LopID VARCHAR(20), -- Nếu VaiTro =  2 Khối Trưởng (BGH) thì LopID = 0
@GiaoVienID VARCHAR(9), 
@MonHocID INT, -- Nếu vai trò in [1,2] thì MonHocID = 0; Nếu Vai trò = 3 thì MonHocID mới set in [1,2,3,4]
@HocKi INT,
@Sys_UserID VARCHAR(9)
AS
BEGIN
	
	--UPDATE [dbo].[tblGiaoVienLop]
	--SET	
	--	VaiTro = @VaiTro,
	--	MonHocID = @MonHocID
	--WHERE LopID = @LopID AND GiaoVienID = @GiaoVienID AND NienKhoa = @NienKhoa AND Enable = 1

	--IF @@ROWCOUNT = 0 
	--BEGIN

	DECLARE @Msg NVARCHAR(200) = ''
	if exists (
		SELECT GiaoVienID FROM tblGiaoVienLop where MonHocID = @MonHocID and LopID = @LopID and Enable = 1 and GiaoVienID = @GiaoVienID and HocKy = @HocKi
	)
	begin
		set @Msg= N'Đã phân công'
		RAISERROR(@Msg, 16 ,1)
		return
	end
		

		INSERT INTO [dbo].[tblGiaoVienLop]([GiaoVienID], [KhoiID], [LopID], [MonHocID], [MaDonVi],[VaiTro], [HocKy], [NienKhoa], [CreateUser])
		VALUES(@GiaoVienID, @KhoiID, @LopID, @MonHocID, 1,3,@HocKi,  @NienKhoa, @Sys_UserID)
	--END 
END 