CREATE PROC [dbo].[spAPI_AUTH_Lop_Upd_ByLopID]
    @LopID INT,
	@GVCN VARCHAR(9),
	@SYS_USERID VARCHAR(9)
AS
BEGIN
    DECLARE @NienKhoa INT = dbo.fn_GetNienKhoa_HienTai();
	UPDATE dbo.tblLop
	SET
		GVCN = @GVCN,
		UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
	WHERE LopID = @LopID AND NienKhoa = @NienKhoa
END;