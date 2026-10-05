-- [dbo].[spAPI_GiaiThuong_QuyetDinh_Upd] 'GV0000611', 171, N'SQD Testing 2',25,4,2024, N'Quyết định test ngày 25/4/2024', 'BE1F1D248CEC45BE9734139E015AB5B5'
CREATE PROC [dbo].[spAPI_GiaiThuong_QuyetDinh_Upd] 
	@Sys_UserId VARCHAR(9),
	@QDID INT,
	@MaSoQD NVARCHAR(50),
	@NgayQD INT,
	@ThangQD INT,
	@NamQD INT,
	@MoTaQD NVARCHAR(500),
	@Dot INT,
	@DS_FileID NVARCHAR(2000)
AS
BEGIN
	DECLARE @LoaiQD INT
	SET @LoaiQD = (SELECT LoaiQD FROM QuyetDinh WHERE QDID  = @QDID)

	-- Kiểm tra mô tả
	IF (@MoTaQD IS NULL OR @MoTaQD = '')
	BEGIN
	    RAISERROR(N'Vui lòng nhập mô tả quyết định', 16, 1)
		RETURN 0;
	END

	UPDATE dbo.QuyetDinh
			SET 
				MaSoQD = @MaSoQD,
				NgayQD = CASE WHEN @NgayQD = 0 THEN NULL ELSE @NgayQD END,
				ThangQD = CASE WHEN @ThangQD = 0 THEN NULL ELSE @ThangQD END,
				NamQD = CASE WHEN @NamQD = 0 THEN NULL ELSE @NamQD END,
				MoTaQD = @MoTaQD,
				FileID_List = @DS_FileID,
				TemplateQD = 1,
				TienDo = @Dot,
				NhanVienCapNhat = @Sys_UserId,
				ThoiGianCapNhat = GETDATE()
			WHERE QDID = @QDID
	
	IF @LoaiQD = 2
	BEGIN
		DECLARE @FileName NVARCHAR(500)
		SET @FileName = (SELECT FILENAME FROM FileData WHERE FILEID = @DS_FileID)
		PRINT @FILENAME
		UPDATE KHCN_TienDoCapKinhPhi
		SET FileID = @DS_FileID,
			[FileName] = @FileName
		FROM KHCN_TienDoCapKinhPhi TD WHERE TD.QDID = @QDID
	END
	
	SELECT [QDID], TienDo AS Dot, [MaSoQD], [NgayQD], [ThangQD], [NamQD], [MoTaQD], [FileID_List], [LoaiQD], [TemplateQD]
	FROM QuyetDinh WHERE QDID = @QDID
END
