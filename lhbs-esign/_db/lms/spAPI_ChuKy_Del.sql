CREATE PROC [dbo].[spAPI_ChuKy_Del]
    @ChuKyID INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblChuKy
    SET Enable = 0,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE ChuKyID = @ChuKyID;
END;