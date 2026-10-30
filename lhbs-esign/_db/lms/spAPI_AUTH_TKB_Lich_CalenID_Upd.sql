CREATE PROCEDURE dbo.spAPI_AUTH_TKB_Lich_CalenID_Upd
        @TKBLichID INT,
        @ThoiKhoaBieu_CalenID VARCHAR(50),
        @sys_UserID VARCHAR(20)
    AS
    BEGIN
        SET NOCOUNT ON;
        UPDATE dbo.tblTKB_Lich
        SET ThoiKhoaBieu_CalenID = @ThoiKhoaBieu_CalenID
        WHERE TKBLichID = @TKBLichID;
        SELECT @TKBLichID AS TKBLichID;
    END