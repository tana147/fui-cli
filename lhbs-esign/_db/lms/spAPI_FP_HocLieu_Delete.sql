CREATE PROCEDURE [dbo].[spAPI_FP_HocLieu_Delete]
    @HocLieuID INT,
    @sys_UserID VARCHAR(50)
AS
BEGIN
    UPDATE dbo.tblHocLieu_FP SET Is_Xoa = 1, UpdateUser = @sys_UserID, UpdateTime = GETDATE() WHERE HocLieuID = @HocLieuID;
    SELECT Success = 1, Message = N'Đã xóa thành công.';
END
