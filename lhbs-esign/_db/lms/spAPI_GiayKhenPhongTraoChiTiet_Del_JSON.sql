CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoChiTiet_Del_JSON]
    @JsonIDs    NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.Enable     = 0
         , t.UpdateUser = @sys_UserID
         , t.UpdateTime = GETDATE()
    FROM
           dbo.tblGiayKhenPhongTraoChiTiet AS t
           INNER JOIN OPENJSON(@JsonIDs)
           WITH
           (
               ChiTietID INT '$'
           ) AS j ON j.ChiTietID = t.ChiTietID
    WHERE
           t.Enable = 1;

    SELECT Deleted = @@ROWCOUNT;
END
