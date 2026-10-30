CREATE PROCEDURE spAPI_TkbGVCamTuyetDoiTuanDelete
    @ID INT,
    @sys_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM tblTKB_GVCamTuyetDoi_Tuan WHERE ID = @ID
    SELECT mess = N'Đã xoá'
END
