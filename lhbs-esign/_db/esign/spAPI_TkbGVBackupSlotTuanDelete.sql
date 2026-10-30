CREATE PROCEDURE spAPI_TkbGVBackupSlotTuanDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM tblTKB_GVBackupSlot_Tuan WHERE ID = @ID
    SELECT mess = N'Đã xoá'
END
