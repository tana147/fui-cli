CREATE PROC [dbo].[spAPI_QuyetDinh_Ins]
	@Sys_UserId VARCHAR(9),
	@MaSoQD NVARCHAR(50),
	@NgayQD INT,
	@ThangQD INT,
	@NamQD INT,
	@MoTaQD NVARCHAR(500),
	@Dot INT,
	@TemplateQD INT,
	@LoaiQD INT,
	@DS_FileID NVARCHAR(2000)
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
		TienDo,
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
		@Dot,
		@DS_FileID,
		@TemplateQD,
		@LoaiQD,
		@Sys_UserId
	)
	
	DECLARE @QDID INT
	SET @QDID = (SELECT @@IDENTITY)

	SELECT [QDID], TienDo AS Dot, [MaSoQD], [NgayQD], [ThangQD], [NamQD], [MoTaQD], [FileID_List], [LoaiQD], [TemplateQD]
	FROM QuyetDinh WHERE QDID = @QDID

END