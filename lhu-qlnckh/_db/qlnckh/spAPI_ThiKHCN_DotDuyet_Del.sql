CREATE PROCEDURE [dbo].[spAPI_ThiKHCN_DotDuyet_Del]
    @DotDuyetID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ThiKHCN_DotDuyet
    SET Is_Xoa = 1
    WHERE DotDuyetID = @DotDuyetID;

    SELECT @@ROWCOUNT AS RowsAffected;
END;
