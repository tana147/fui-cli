CREATE PROC [dbo].[spAPI_BaoCao_TongHop_Ins_ByBaoCaoID]
	@BaoCaoID		INT,
	@HocKi			VARCHAR(50), 
	@JSON_BaoCao NVARCHAR(MAX),
	@Url_BaoCao VARCHAR(200),
	@TenBaoCao_ChiTiet NVARCHAR(200),
	@NienKhoa	INT,
	@SYS_USERID VARCHAR(9)
AS
BEGIN
    INSERT INTO tblBaoCao_ChiTiet
	(
		[BaoCaoID], 
		[HocKi], 
		[JSON_BaoCao], 
		Url_BaoCao,
		TenBaoCao_ChiTiet,
		NienKhoa,
		[Enable], 
		[NguoiTao], 
		[NgayTao]
	)
	VALUES (
		@BaoCaoID,
		@HocKi,
		@JSON_BaoCao,
		@Url_BaoCao,
		@TenBaoCao_ChiTiet,
		@NienKhoa,
		1,
		@SYS_USERID,
		GETDATE()
	)

END