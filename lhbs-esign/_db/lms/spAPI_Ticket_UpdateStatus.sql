
-- =============================================
-- 4. UPDATE STATUS
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_UpdateStatus]
    @TicketID INT,
    @Status VARCHAR(20),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldStatus VARCHAR(20);

    SELECT @OldStatus = Status FROM Tickets WHERE TicketID = @TicketID;

    UPDATE Tickets
    SET Status = @Status,
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE TicketID = @TicketID AND IsDeleted = 0;

    INSERT INTO TicketLogs (TicketID, Action, OldValue, NewValue, CreateUser, CreateTime)
    VALUES (@TicketID, 'STATUS', @OldStatus, @Status, @SYS_USERID, GETDATE());
END
