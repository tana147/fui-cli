
-- =============================================
-- 3. ASSIGN (actor assigns owner)
-- =============================================
CREATE   PROC [dbo].[spAPI_Ticket_Assign]
    @TicketID INT,
    @AssignedTo VARCHAR(9),
    @SYS_USERID VARCHAR(9)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldAssignedTo VARCHAR(9);

    SELECT @OldAssignedTo = AssignedTo FROM Tickets WHERE TicketID = @TicketID;

    UPDATE Tickets
    SET AssignedTo = @AssignedTo,
        Status = 'IN_PROGRESS',
        UpdateUser = @SYS_USERID,
        UpdateTime = GETDATE()
    WHERE TicketID = @TicketID AND IsDeleted = 0;

    -- LOG (actor = SYS_USERID, owner change tracked)
    INSERT INTO TicketLogs (TicketID, Action, OldValue, NewValue, CreateUser, CreateTime)
    VALUES (@TicketID, 'ASSIGN', @OldAssignedTo, @AssignedTo, @SYS_USERID, GETDATE());
END
