CREATE PROC [dbo].[spAPI_ChuKy_Udp]
    @ChuKyID INT,
    @GiaoVienID VARCHAR(9),
    @HinhAnhChuKy CHAR(32),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblChuKy
    SET GiaoVienID = @GiaoVienID,
        HinhAnhChuKy = @HinhAnhChuKy,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE ChuKyID = @ChuKyID;
END;