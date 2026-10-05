CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Ins]
	@Sys_UserId VARCHAR(9),
	@MaSoQD NVARCHAR(50),
	@NgayQD INT,
	@ThangQD INT,
	@NamQD INT,
	@MoTaQD NVARCHAR(500),
	@TemplateQD INT,
	@LoaiQD INT
AS
BEGIN
	-- Kiểm tra mô tả
	IF (@MoTaQD IS NULL OR @MoTaQD = '')
	BEGIN
	    RAISERROR(N'Vui lòng nhập mô tả quyết định', 16, 1)
		RETURN 0;
	END

	INSERT INTO dbo.QuyetDinh
	(
	    MaSoQD,
	    NgayQD,
	    ThangQD,
	    NamQD,
	    MoTaQD,
		FileID_List,
		TemplateQD,
		LoaiQD,
	    NhanVienCapNhat
	)
	VALUES 
	(
		@MaSoQD,
		CASE WHEN @NgayQD = 0 THEN NULL ELSE @NgayQD END,
		CASE WHEN @ThangQD = 0 THEN NULL ELSE @ThangQD END,
		CASE WHEN @NamQD = 0 THEN NULL ELSE @NamQD END,
	    @MoTaQD,
		'',
		@TemplateQD,
		@LoaiQD,
		@Sys_UserId
	)
	
	SELECT @@IDENTITY  AS QDID	

END