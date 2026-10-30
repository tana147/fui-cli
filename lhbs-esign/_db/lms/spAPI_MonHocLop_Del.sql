CREATE PROC spAPI_MonHocLop_Del
    @MonHocLopID INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    UPDATE dbo.tblMonHocLop
    SET Enable = 0,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE MonHocLopID = @MonHocLopID;
END;