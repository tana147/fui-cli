
-- Bulk reorder: nhận JSON array [{WorkItemID, SortOrder}]
CREATE PROCEDURE [dbo].[spAPI_WF_WorkItem_Reorder]
    @sys_UserID VARCHAR(9),
    @OrderJSON  NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRY
        IF @OrderJSON IS NULL OR @OrderJSON = ''
        BEGIN
            SELECT CAST(0 AS BIT) AS Success, N'OrderJSON không được trống.' AS Message
            RETURN
        END

        BEGIN TRANSACTION

        UPDATE W
        SET W.SortOrder  = J.SortOrder,
            W.UpdateUser = @sys_UserID,
            W.UpdateTime = GETDATE()
        FROM dbo.tblWF_WorkItem AS W
        INNER JOIN OPENJSON(@OrderJSON) WITH
        (
            WorkItemID BIGINT,
            SortOrder  INT
        ) AS J ON J.WorkItemID = W.WorkItemID
        WHERE W.[Enable] = 1

        COMMIT TRANSACTION

        SELECT CAST(1 AS BIT) AS Success, N'Đã lưu thứ tự.' AS Message
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
        SELECT CAST(0 AS BIT) AS Success, ERROR_MESSAGE() AS Message
    END CATCH
END
