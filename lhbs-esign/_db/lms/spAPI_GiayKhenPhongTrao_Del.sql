
CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTrao_Del]
    @PhongTraoID INT
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.tblGiayKhenPhongTrao
    SET Enable = 0
      , UpdateUser = @sys_UserID
      , UpdateTime = GETDATE()
    WHERE PhongTraoID = @PhongTraoID;

    UPDATE dbo.tblGiayKhenPhongTraoChiTiet
    SET Enable = 0
      , UpdateUser = @sys_UserID
      , UpdateTime = GETDATE()
    WHERE PhongTraoID = @PhongTraoID;

    UPDATE dbo.tblGiayKhenPhongTraoDong
    SET Enable = 0
      , UpdateUser = @sys_UserID
      , UpdateTime = GETDATE()
    WHERE PhongTraoID = @PhongTraoID;

    SELECT Deleted = @@ROWCOUNT;
END;
