CREATE PROC [dbo].[spAPI_ToTrinh_Del]
@ToTrinhID INT,
@SYS_UserID VARCHAR(9)
AS
BEGIN
	UPDATE ToTrinh SET is_xoa = 1, [Updated_By]  = @SYS_UserID, [Updated_At] = GETDATE() WHERE ToTrinhID = @ToTrinhID
	UPDATE AnPham SET ToTrinhID = NULL WHERE ToTrinhID = @ToTrinhID
END