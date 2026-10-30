
-- =============================================
-- 5. DELETE
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_Delete]
    @TicketID INT,
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Tickets
    SET IsDeleted = 1,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE TicketID = @TicketID;

    INSERT INTO TicketLogs (TicketID, Action, CreateUser, CreateTime)
    VALUES (@TicketID, 'DELETE', @SYS_USERID, GETDATE());
END
