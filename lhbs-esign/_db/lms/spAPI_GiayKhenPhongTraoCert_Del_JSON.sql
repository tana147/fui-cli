CREATE PROCEDURE [dbo].[spAPI_GiayKhenPhongTraoCert_Del_JSON]
    @JsonIDs    NVARCHAR(MAX)
  , @sys_UserID VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE t
    SET    t.Enable = 0
         , t.UpdateUser = @sys_UserID
         , t.UpdateTime = GETDATE()
    FROM
           dbo.tblGiayKhenPhongTraoCert AS t
           INNER JOIN OPENJSON(@JsonIDs) WITH ( PhongTraoCertID INT '$' ) AS j
                   ON j.PhongTraoCertID = t.PhongTraoCertID
    WHERE
           t.Enable = 1;

    SELECT Deleted = @@ROWCOUNT;
END