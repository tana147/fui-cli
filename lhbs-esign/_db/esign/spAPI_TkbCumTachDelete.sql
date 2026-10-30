CREATE PROCEDURE spAPI_TkbCumTachDelete
    @url1_ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTKB_CumTach
    SET Enable = 0, UpdateUser = @sys_UserID, UpdateTime = GETDATE()
    WHERE ID = @url1_ID;

    SELECT N'Đã xoá' AS mess, @url1_ID AS id;
END
