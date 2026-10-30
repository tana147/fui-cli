CREATE PROC [dbo].[spAPI_GiaoVienLop_Upd]
@NienKhoa INT = 2024,
@GVLopID	INT,
@KhoiID		INT,
@LopID		INT, -- Nếu VaiTro =  2 Khối Trưởng (BGH) thì LopID = 0
@GiaoVienID VARCHAR(9), 
@VaiTro		INT, -- 1: Giáo viên Lớp; 2: Khối Trưởng (Duyệt); 3: Giáo viên bộ môn (Tiếng Anh, Kỹ Năng)
@MonHocID	INT, -- Nếu vai trò in [1,2] thì MonHocID = 0; Nếu Vai trò = 3 thì MonHocID mới set in [1,2,3,4]
@MaDonVi	INT,
@Sys_UserID VARCHAR(9)
AS
BEGIN
	UPDATE [dbo].[tblGiaoVienLop]
	SET	
		KhoiID		= @KhoiID,		
		LopID		= @LopID,		
		GiaoVienID	= @GiaoVienID,
		VaiTro		= @VaiTro,	
		MonHocID	= @MonHocID,
		MaDonVi		= @MaDonVi,
		UpdateTime	= GETDATE(),
		UpdateUser	= @Sys_UserID
	WHERE GVLopID = @GVLopID AND NienKhoa = @NienKhoa
END