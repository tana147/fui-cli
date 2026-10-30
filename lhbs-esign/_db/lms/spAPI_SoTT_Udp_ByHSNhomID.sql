
CREATE PROC spAPI_SoTT_Udp_ByHSNhomID
	@HSNhomID INT,
	@SoTT INT,
	@SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblHocSinhNhom
	SET
		SoTT = @SoTT,
		UpdateUser = @SYS_USERID,
		UpdateTime = GETDATE()
	WHERE HSNhomID = @HSNhomID
END