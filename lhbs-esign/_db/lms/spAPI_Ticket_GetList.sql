-- =============================================
-- 6. GET LIST
-- =============================================
CREATE PROC [dbo].[spAPI_Ticket_GetList]
    @Status VARCHAR(20) = NULL,
    @AssignedTo VARCHAR(9) = NULL,
    @CreateUser VARCHAR(9) = NULL,
    @IsIT BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        t.TicketID,
        t.Title,
        t.Status,
        t.AssignedTo,
        t.CreateUser,
        t.CreateTime,
        (SELECT COUNT(*) FROM TicketComments c
         WHERE c.TicketID = t.TicketID
           AND c.IsSeenByIT = 0) AS UnreadIT,
        (SELECT COUNT(*) FROM TicketComments c
         WHERE c.TicketID = t.TicketID
           AND c.IsSeenByUser = 0
           AND c.IsInternal = 0) AS UnreadUser
    FROM Tickets t
    WHERE t.IsDeleted = 0
      AND (@Status IS NULL OR t.Status = @Status)
      AND (@AssignedTo IS NULL OR t.AssignedTo = @AssignedTo)
      AND (@CreateUser IS NULL OR t.CreateUser = @CreateUser)
    ORDER BY t.CreateTime DESC;
END
