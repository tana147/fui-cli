CREATE PROCEDURE [dbo].[spAPI_GiayKhenTapTheCert_Del_JSON]
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
           dbo.tblGiayKhenTapTheCert AS t
           INNER JOIN OPENJSON(@JsonIDs) WITH ( HocBongCertID INT '$' ) AS j
                   ON j.HocBongCertID = t.GiayKhenCertID
    WHERE
           t.Enable = 1;

    SELECT Deleted = @@ROWCOUNT;
END