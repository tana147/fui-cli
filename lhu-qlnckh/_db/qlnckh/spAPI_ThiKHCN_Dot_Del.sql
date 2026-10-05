CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_Dot_Del]
    @DotID INT,
    @SYS_UserID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ThiKHCN_Dot
    SET Is_Xoa = 1
    WHERE DotID = @DotID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
