
CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Ins]
	@CapID INT,
	@MonHocID INT,
	@TenBaoCao NVARCHAR(400),
	@SYS_USERID VARCHAR(9)
AS
BEGIN
   INSERT INTO tblBaoCao (
		CapID,
		MonHocID,
		TenBaoCao,
		[Enable],
		CreateUser,
		CreateTime
   )
   VALUES 
   (
	    @CapID,
		ISNULL(@MonHocID, 0),
		@TenBaoCao,
		1,
		@SYS_USERID,
		GETDATE()
   )
END

